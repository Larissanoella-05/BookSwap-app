/// ============================================================================
/// HOME SCREEN - MAIN APP INTERFACE
/// ============================================================================
/// 
/// This is the main screen of the app after login. It contains:
/// - Bottom navigation bar (Browse, My Listings, Chats, Settings)
/// - Tab-based screen switching using IndexedStack
/// - Special handling for "My Listings" tab (uses TabBarView)
/// - Floating action button on Browse tab (to add new book)
/// 
/// NAVIGATION STRUCTURE:
/// - Tab 0: Browse - Browse all book listings
/// - Tab 1: My Listings - User's own books + received swap offers (has sub-tabs)
/// - Tab 2: Chats - List of chat conversations
/// - Tab 3: Settings - User profile and app settings
/// 
/// STATE MANAGEMENT:
/// - Uses Riverpod's selectedTabIndexProvider to track current tab
/// - IndexedStack keeps all tabs in memory (faster switching, no rebuild)
/// 
/// SPECIAL CASES:
/// - Tab 1 (My Listings) uses DefaultTabController with TabBarView
///   instead of IndexedStack because it has sub-tabs (My Books / My Offers)
/// - Tab 0 (Browse) shows FloatingActionButton to add new book
/// 
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookswap/Layouts/top-navigation.dart';
import 'package:bookswap/Layouts/bottom-navigation.dart';
import 'package:bookswap/Layouts/browse-layout.dart';
import 'package:bookswap/Layouts/listing-layout.dart';
import 'package:bookswap/Layouts/chat-layout.dart';
import 'package:bookswap/Layouts/settings-layout.dart';
import 'package:bookswap/Screens/my_offers.dart';
import 'package:bookswap/routes/routes.dart';
import 'package:bookswap/Firebase/auth_providers.dart';
import 'package:bookswap/Widgets/notification_listener_widget.dart';

/// Riverpod provider for tracking the currently selected bottom navigation tab
/// 
/// Values:
/// - 0: Browse tab
/// - 1: My Listings tab
/// - 2: Chats tab
/// - 3: Settings tab
/// 
/// Updated when user taps bottom navigation items.
final selectedTabIndexProvider = StateProvider<int>((ref) => 0);

/// Main home screen widget
/// 
/// Handles the main app interface with bottom navigation.
/// Wraps all screens in NotificationListenerWidget to listen for new messages/swaps.
class Home extends ConsumerWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch current selected tab index (0-3)
    final selectedIndex = ref.watch(selectedTabIndexProvider);
    
    // Watch current user from Firebase Auth stream
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.value; // Get current value from stream

    // List of screens corresponding to each bottom nav tab
    // IndexedStack keeps all screens in memory for fast switching
    final screens = [
      const BrowseScreen(),      // Tab 0: Browse all books
      const MyListingsScreen(),  // Tab 1: User's own books (special case - see below)
      const ChatsScreen(),       // Tab 2: Chat conversations
      const SettingsScreen(),    // Tab 3: User settings
    ];

    // SPECIAL CASE: My Listings tab (index 1) uses TabBarView instead of IndexedStack
    // because it has sub-tabs: "My Books" and "My Offers"
    if (selectedIndex == 1) {
      return NotificationListenerWidget(
        child: DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: const Color.fromARGB(255, 252, 252, 252),
            appBar: AppBar(
              title: const Text('My Listings', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              centerTitle: true,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 250, 174, 22)),
              ),
              backgroundColor: const Color.fromARGB(255, 5, 22, 46),
              foregroundColor: Colors.white,
              titleTextStyle: const TextStyle(color: Colors.white),
              bottom: const TabBar(
                labelColor: const Color.fromARGB(255, 250, 174, 22),
                unselectedLabelColor: Colors.white,
                indicatorColor: const Color.fromARGB(255, 250, 174, 22),
                tabs: [
                  Tab(text: 'My Books'),
                  Tab(text: 'My Offers'),
                ],
              ),
            ),
            body: const TabBarView(
              children: [
                ListingLayout(),
                MyOffersScreen(),
              ],
            ),
            bottomNavigationBar: BottomNavigation(context, selectedIndex: selectedIndex),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.addBook);
              },
              backgroundColor: const Color.fromARGB(255, 5, 22, 46),
              child: const Icon(
                Icons.add,
                color: Color.fromARGB(255, 255, 255, 255),
                size: 30,
              ),
            ),
          ),
        ),
      );
    }

    // Build appropriate AppBar based on selected tab
    // Each tab can have a custom AppBar with different title and actions
    PreferredSizeWidget? appBar;
    if (selectedIndex == 2) {
      // Chats tab - show "Chat Section" with user avatar
      appBar = AppBar(
        toolbarHeight: 80,
        actionsPadding: EdgeInsets.all(10),
        backgroundColor: const Color.fromARGB(255, 5, 22, 46),
        titleTextStyle: TextStyle(color: Colors.white),
        title: Text('Chat Section', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          onPressed: () async {
            if (context.mounted) {
              Navigator.pushNamed(context, AppRoutes.home);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error logging out'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          icon: Icon(Icons.arrow_back, color: const Color.fromARGB(255, 250, 174, 22)),
        ),
        actions: [
          Container(
            width: 40,
            height: 40,
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: ClipOval(
              child: (user?.photoURL != null && user!.photoURL!.isNotEmpty)
                  ? Image(
                      image: NetworkImage(user.photoURL!),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color.fromARGB(255, 190, 190, 190),
                      child: Text(
                        (user?.displayName != null && user!.displayName!.isNotEmpty)
                            ? user.displayName!.substring(0, 1).toUpperCase()
                            : (user?.email != null && user!.email!.isNotEmpty)
                                ? user.email!.substring(0, 1).toUpperCase()
                                : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      );
    } else if (selectedIndex == 3) {
      // Settings tab - show "Profile Settings"
      appBar = AppBar(
        toolbarHeight: 80,
        actionsPadding: EdgeInsets.all(10),
        backgroundColor: const Color.fromARGB(255, 5, 22, 46),
        titleTextStyle: TextStyle(color: Colors.white),
        title: Text('Profile Settings', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          onPressed: () async {
            if (context.mounted) {
              Navigator.pushNamed(context, AppRoutes.home);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error logging out'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          icon: Icon(Icons.arrow_back, color: const Color.fromARGB(255, 250, 174, 22)),
        ),
        actions: [
          Container(
            width: 40,
            height: 40,
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: ClipOval(
              child: (user?.photoURL != null && user!.photoURL!.isNotEmpty)
                  ? Image(
                      image: NetworkImage(user.photoURL!),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color.fromARGB(255, 190, 190, 190),
                      child: Text(
                        (user?.displayName != null && user!.displayName!.isNotEmpty)
                            ? user.displayName!.substring(0, 1).toUpperCase()
                            : (user?.email != null && user!.email!.isNotEmpty)
                                ? user.email!.substring(0, 1).toUpperCase()
                                : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      );
    } else {
      // Browse tab (0) and Settings tab (3) use topNavigation widget
      appBar = topNavigation(context, user, ref);
    }

    // For tabs 0, 2, and 3: Use IndexedStack to switch between screens
    // IndexedStack keeps all screens in memory (faster, but uses more memory)
    // Wrapped in NotificationListenerWidget to listen for new messages/swaps
    return NotificationListenerWidget(
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 252, 252, 252),
        appBar: appBar,
        // IndexedStack shows only the screen at selectedIndex
        // All screens stay in memory for instant switching
        body: IndexedStack(
          index: selectedIndex,
          children: screens,
        ),
        // Bottom navigation bar (Browse, My Listings, Chats, Settings)
        bottomNavigationBar: BottomNavigation(context, selectedIndex: selectedIndex),
        // Floating action button only shown on Browse tab (to add new book)
        floatingActionButton: selectedIndex == 0
              ? FloatingActionButton(
                  onPressed: () {
                    // Navigate to add book screen
                    Navigator.pushNamed(context, AppRoutes.addBook);
                  },
                backgroundColor: const Color.fromARGB(255, 15, 23, 61),
                  child: const Icon(
                    Icons.add,
                  color: Color.fromARGB(255, 255, 255, 255),
                    size: 30,
                  ),
                )
              : null,
      ),
    );
  }
}

/// Browse Screen - Shows all book listings
class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BrowseLayout();
  }
}

/// My Listings Screen - Shows user's own books with tab for My Offers
/// Note: This widget is not used when selectedIndex == 1 because TabBarView
/// is handled directly in the Home widget. This is kept for compatibility.
class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This should never be rendered when selectedIndex == 1
    // because Home returns a different structure for that case
    return const ListingLayout();
  }
}

/// Chats Screen - Shows chat conversations
class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ChatLayout();
  }
}

/// Settings Screen - Shows user settings and profile
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsLayout();
  }
}

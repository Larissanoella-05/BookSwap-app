// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../models/book.dart';
import '../utils/image_helper.dart';
import '../providers/book_provider.dart';
import '../providers/swap_provider.dart';
import '../providers/chat_provider.dart';
import 'welcome_screen.dart';
import 'post_book.dart';
import 'book_details_screen.dart';
import 'edit_book_screen.dart';
import 'my_offers_screen.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  // Track which tab is currently selected (0 = first tab, 1 = second, etc.)
  int _selectedIndex = 0;

  // List of screens for each tab
  final List<Widget> _screens = [
    const BrowseListingsScreen(),
    const MyListingsScreen(),
    const MyOffersScreen(), // Replaced Chats with My Offers
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Start listening to pending offers count and unread messages for notification badge
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SwapProvider>().listenToPendingOffersCount();
      context.read<ChatProvider>().listenToTotalUnreadCount();
    });
  }

  // Function to handle tab changes
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The currently selected screen
      body: _screens[_selectedIndex],

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Fixed shows all items
        backgroundColor: const Color(0xFF2C2855),
        selectedItemColor: const Color(0xFFF5C344), // Yellow when selected
        unselectedItemColor: Colors.white60,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Browse',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'My Listings',
          ),
          BottomNavigationBarItem(
            icon: Consumer<SwapProvider>(
              builder: (context, swapProvider, child) {
                final pending = swapProvider.pendingOffersCount;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.swap_horiz),
                    if (pending > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$pending',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: 'My Offers',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ==================== SCREEN 1: Browse Listings ====================
class BrowseListingsScreen extends StatefulWidget {
  const BrowseListingsScreen({super.key});

  @override
  State<BrowseListingsScreen> createState() => _BrowseListingsScreenState();
}

class _BrowseListingsScreenState extends State<BrowseListingsScreen> {
  @override
  void initState() {
    super.initState();
    // Start listening to books when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookProvider>().listenToAllBooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Listings'),
        backgroundColor: const Color(0xFF2C2855),
        foregroundColor: Colors.white,
      ),
      body: Consumer<BookProvider>(
        builder: (context, bookProvider, child) {
          // Loading state
          if (bookProvider.isLoading && bookProvider.allBooks.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2C2855)),
            );
          }

          // Error state
          if (bookProvider.error != null && bookProvider.allBooks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${bookProvider.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => bookProvider.fetchAllBooks(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // No data state
          if (bookProvider.allBooks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No books available yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to post a book!',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          // Display books in a grid
          final books = bookProvider.allBooks;
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 columns
              childAspectRatio: 0.65, // Card height ratio
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return _BookCard(book: book);
            },
          );
        },
      ),
    );
  }
}

/// Book Card Widget - Displays individual book
class _BookCard extends StatelessWidget {
  final Book book;

  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigating to book details page
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BookDetailsScreen(book: book),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover image section
            BookCoverImage(
              imageUrl: book.imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),

            // Book details section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Book title
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C2855),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Author
                    Text(
                      'by ${book.author}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),

                    // Condition badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getConditionColor(book.condition),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        book.condition,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get color based on book condition
  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'new':
        return const Color.fromARGB(255, 65, 130, 174);
      case 'like new':
        return const Color.fromARGB(255, 104, 35, 35);
      case 'good':
        return const Color.fromARGB(255, 109, 87, 52);
      case 'fair':
        return const Color.fromARGB(255, 18, 38, 26);
      default:
        return Colors.grey;
    }
  }
}

// ==================== SCREEN 2: My Listings ====================
class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  @override
  void initState() {
    super.initState();
    // Start listening to user's books when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookProvider>().listenToMyBooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        backgroundColor: const Color(0xFF2C2855),
        foregroundColor: Colors.white,
      ),
      body: Consumer<BookProvider>(
        builder: (context, bookProvider, child) {
          // Loading state
          if (bookProvider.isLoading && bookProvider.myBooks.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2C2855)),
            );
          }

          // Error state
          if (bookProvider.error != null && bookProvider.myBooks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Color.fromARGB(255, 78, 47, 45),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${bookProvider.error}',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 67, 33, 30),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => bookProvider.fetchMyBooks(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // No data state
          if (bookProvider.myBooks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.library_books_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No books posted yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to post your first book!',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          // Display user's books in a list
          final books = bookProvider.myBooks;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return _MyBookCard(book: book);
            },
          );
        },
      ),
      // Floating action button to add new book
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigating to Post a Book screen
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const PostBookScreen()),
          );
        },
        backgroundColor: const Color.fromARGB(255, 189, 153, 63),
        child: const Icon(Icons.add, color: Color.fromARGB(255, 31, 28, 66)),
      ),
    );
  }
}

/// My Book Card Widget - Shows user's own books with edit/delete options
class _MyBookCard extends StatelessWidget {
  final Book book;

  const _MyBookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigating to book details page
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BookDetailsScreen(book: book),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book cover image section
              BookCoverImage(
                imageUrl: book.imageUrl,
                width: 80,
                height: 120,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(8),
              ),

              const SizedBox(width: 12),

              // Book details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C2855),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by ${book.author}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getConditionColor(book.condition),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            book.condition,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: book.status == 'available'
                                ? const Color.fromARGB(255, 48, 103, 50)
                                : Colors.grey,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            book.status,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Swap for: ${book.swapFor}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Action buttons
              PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete,
                          size: 20,
                          color: Color.fromARGB(255, 88, 29, 24),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: Color.fromARGB(255, 101, 38, 34),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    // Navigating to edit screen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => EditBookScreen(book: book),
                      ),
                    );
                  } else if (value == 'delete') {
                    // Showing delete confirmation
                    _showDeleteConfirmation(context, book);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Showing delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context, Book book) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text('Are you sure you want to delete "${book.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Deleting using Provider
                await context.read<BookProvider>().deleteBook(book.id);

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Book deleted successfully'),
                      backgroundColor: Color.fromARGB(255, 38, 88, 40),
                    ),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: $e'),
                      backgroundColor: const Color.fromARGB(255, 72, 29, 26),
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Color.fromARGB(255, 121, 45, 40)),
            ),
          ),
        ],
      ),
    );
  }

  /// Getting color based on book condition
  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'new':
        return const Color.fromARGB(255, 65, 130, 174);
      case 'like new':
        return const Color.fromARGB(255, 104, 35, 35);
      case 'good':
        return const Color.fromARGB(255, 109, 87, 52);
      case 'fair':
        return const Color.fromARGB(255, 18, 38, 26);
      default:
        return Colors.grey;
    }
  }
}

// ==================== SCREEN 3: Chats ====================
class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: const Color(0xFF2C2855),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Your conversations will appear here',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

// ==================== SCREEN 4: Settings ====================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();

  // Settings toggles
  bool _notificationsEnabled = true;
  bool _emailUpdatesEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  /// Load saved preferences from SharedPreferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _emailUpdatesEnabled = prefs.getBool('email_updates_enabled') ?? false;
      _isLoading = false;
    });
  }

  /// Save notification preference
  Future<void> _saveNotificationPreference(bool value) async {
    // Capture context reference before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() {
      _notificationsEnabled = value;
    });

    // Showing confirmation message (local simulation)
    if (mounted) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            value
                ? '🔔 Push notifications enabled'
                : '🔕 Push notifications disabled',
          ),
          backgroundColor: value
              ? const Color.fromARGB(255, 41, 104, 44)
              : Colors.grey,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Save email updates preference
  Future<void> _saveEmailUpdatesPreference(bool value) async {
    // Capture context reference before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('email_updates_enabled', value);
    setState(() {
      _emailUpdatesEnabled = value;
    });

    // Showing confirmation message (local simulation)
    if (mounted) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            value ? 'Email updates enabled' : 'Email updates disabled',
          ),
          backgroundColor: value
              ? const Color.fromARGB(255, 33, 85, 35)
              : Colors.grey,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color.fromARGB(255, 35, 31, 72),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Profile Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2855),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color.fromARGB(255, 160, 126, 39),
                  child: Text(
                    user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2855),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.email ?? 'User',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Member since ${DateTime.now().year}',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Notification Settings
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Notifications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),

          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive notifications about swap offers'),
            value: _notificationsEnabled,
            activeTrackColor: const Color.fromARGB(255, 144, 113, 35),
            onChanged: _isLoading ? null : _saveNotificationPreference,
          ),

          SwitchListTile(
            title: const Text('Email Updates'),
            subtitle: const Text('Receive email about swap offers'),
            value: _emailUpdatesEnabled,
            activeTrackColor: const Color.fromARGB(255, 144, 113, 35),
            onChanged: _isLoading ? null : _saveEmailUpdatesPreference,
          ),

          const Divider(),

          // About Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'About',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms & Conditions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Show terms
            },
          ),

          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Show privacy policy
            },
          ),

          const Divider(),

          // Sign out button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () async {
                // Showing confirmation dialog
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );

                if (shouldLogout == true) {
                  await _authService.signOut();
                  if (!mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 121, 62, 58),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

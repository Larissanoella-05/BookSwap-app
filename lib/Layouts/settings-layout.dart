import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bookswap/Firebase/auth_providers.dart';
import 'package:bookswap/Services/profile_providers.dart';
import 'package:bookswap/Services/book_providers.dart';
import 'package:bookswap/Services/swap_providers.dart';
import 'package:bookswap/Services/chat_providers.dart';
import 'package:bookswap/Screens/home.dart';
import 'package:bookswap/Services/notification_listener.dart';
import 'package:bookswap/routes/routes.dart';
import 'dart:io';

/// Provider for notification preferences
final notificationsEnabledProvider = StateNotifierProvider<NotificationsNotifier, bool>((ref) {
  return NotificationsNotifier();
});

class NotificationsNotifier extends StateNotifier<bool> {
  NotificationsNotifier() : super(true) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('notifications_enabled') ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', state);
  }
}

/// Provider for email update preferences
final emailUpdatesEnabledProvider = StateProvider<bool>((ref) => true);

/// Settings Layout - Shows user settings and profile
class SettingsLayout extends ConsumerWidget {
  const SettingsLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserStreamProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final emailUpdatesEnabled = ref.watch(emailUpdatesEnabledProvider);
    final authService = ref.read(authServiceProvider);

    return currentUserAsync.when(
      data: (currentUser) {
        if (currentUser == null) {
          return const Center(
            child: Text('Please log in to view settings'),
          );
        }
        
        return _buildSettingsContent(context, ref, currentUser, notificationsEnabled, emailUpdatesEnabled, authService);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }

  Widget _buildSettingsContent(
    BuildContext context,
    WidgetRef ref,
    currentUser,
    bool notificationsEnabled,
    bool emailUpdatesEnabled,
    authService,
  ) {

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Profile Section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color.fromARGB(255, 250, 174, 22),
                    backgroundImage: currentUser.photoURL != null && currentUser.photoURL!.isNotEmpty
                              ? NetworkImage(currentUser.photoURL!)
                              : null,
                    child: currentUser.photoURL == null || currentUser.photoURL!.isEmpty
                              ? Text(
                                  currentUser.displayName?.substring(0, 1).toUpperCase() ??
                                      currentUser.email?.substring(0, 1).toUpperCase() ??
                                      'U',
                                  style: const TextStyle(
                              fontSize: 32,
                                    color: Colors.white,
                              fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                    child: GestureDetector(
                      onTap: () => _changeProfilePicture(context, ref),
                          child: Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 5, 22, 46),
                              shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                            ),
                        padding: const EdgeInsets.all(6),
                            child: const Icon(
                              Icons.camera_alt,
                          size: 18,
                              color: Colors.white,
                        ),
                            ),
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 16),
                          Text(
                            currentUser.displayName ?? 'No name',
                            style: const TextStyle(
                  fontSize: 20,
                              fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentUser.email ?? 'No email',
                style: TextStyle(
                              fontSize: 14,
                  color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                child: OutlinedButton(
                    onPressed: () => _changeProfilePicture(context, ref),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey[300]!),
                    ),
                  child: const Text('Change Profile Picture'),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        // Notifications Section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
                ),
          child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Enable Notifications',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                    ),
                    Switch(
                      value: notificationsEnabled,
                      onChanged: (value) {
                        ref.read(notificationsEnabledProvider.notifier).toggle();
                      },
                      activeTrackColor: const Color.fromARGB(255, 5, 22, 46),
                      activeThumbColor: const Color.fromARGB(255, 250, 174, 22),
                    ),
                  ],
          ),
        ),
        const SizedBox(height: 20),
        // Email Updates Section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Email Updated',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Switch(
                value: emailUpdatesEnabled,
                onChanged: (value) {
                  ref.read(emailUpdatesEnabledProvider.notifier).state = value;
                },
                activeTrackColor: const Color.fromARGB(255, 5, 22, 46),
                activeThumbColor: const Color.fromARGB(255, 250, 174, 22),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Log Out Section
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Log Out',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
                ),
                onTap: () async {
                  // Show confirmation dialog
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Log Out'),
                      content: const Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Log Out'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    try {
                      // Clear all user-specific data before signing out
                      await _clearUserData(ref);
                      
                      // Invalidate ALL providers to stop streams and clear cached data
                      // This must happen BEFORE signOut to properly cancel Firestore listeners
                      ref.invalidate(authStateChangesProvider);
                      ref.invalidate(currentUserStreamProvider);
                      ref.invalidate(currentUserProvider);
                      ref.invalidate(selectedTabIndexProvider);
                      ref.invalidate(notificationsEnabledProvider);
                      ref.invalidate(emailUpdatesEnabledProvider);
                      
                      // Clear notification listener state
                      ref.invalidate(lastSeenSwapIdsProvider);
                      ref.invalidate(lastSeenMessageIdsProvider);
                      
                      // Invalidate all data providers to stop streams and clear cache
                      // This prevents permission errors from lingering streams
                      ref.invalidate(allBooksProvider);
                      ref.invalidate(userBooksProvider);
                      ref.invalidate(myOffersProvider);
                      ref.invalidate(receivedOffersProvider);
                      ref.invalidate(userChatsProvider);
                      ref.invalidate(chatMessagesProvider);
                      
                      // Sign out after invalidating providers
                      await authService.signOut();
                      
                      // Small delay to ensure all streams are cancelled
                      await Future.delayed(const Duration(milliseconds: 100));
                      
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, AppRoutes.login);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error logging out: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
          ),
        ),
      ],
    );
  }

  /// Clear all user-specific data on logout
  Future<void> _clearUserData(WidgetRef ref) async {
    try {
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // Note: Riverpod providers will be invalidated separately
      // This ensures all cached data is cleared
    } catch (e) {
      debugPrint('Error clearing user data: $e');
    }
  }

  Future<void> _changeProfilePicture(BuildContext context, WidgetRef ref) async {
    final profileService = ref.read(profileServiceProvider);
    final imagePicker = ImagePicker();

    try {
      // Show options: Camera or Gallery
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      // Pick image
      final XFile? pickedFile = await imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Upload profile picture
      final imageFile = File(pickedFile.path);
      await profileService.uploadProfilePicture(imageFile);

      // Reload user to get updated photoURL
      final user = ref.read(authServiceProvider).currentUser;
      if (user != null) {
        await user.reload();
        // Invalidate both stream providers to force a refresh everywhere
        ref.invalidate(currentUserStreamProvider);
        ref.invalidate(authStateChangesProvider);
      }

      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}


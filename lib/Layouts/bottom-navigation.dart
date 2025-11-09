/// ============================================================================
/// BOTTOM NAVIGATION BAR
/// ============================================================================
/// 
/// Custom bottom navigation bar with 4 tabs:
/// - Browse (home icon) - Browse all book listings
/// - My Listings (library icon) - User's own books and received offers
/// - Chats (message icon) - Chat conversations
/// - Settings (settings icon) - User profile and app settings
/// 
/// HOW IT WORKS:
/// - Updates selectedTabIndexProvider when a tab is tapped
/// - Home screen watches this provider and switches screens accordingly
/// - Selected tab is highlighted (white color, larger icon)
/// - Unselected tabs are grayed out
/// 
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookswap/Screens/home.dart';

/// Bottom navigation bar widget
/// 
/// Displays 4 navigation tabs at the bottom of the screen.
/// Updates selectedTabIndexProvider when tabs are tapped.
class BottomNavigation extends ConsumerWidget {
  /// Currently selected tab index (0-3)
  final int selectedIndex;

  const BottomNavigation(BuildContext context, {required this.selectedIndex, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Container with dark blue background, 9% of screen height
    return ClipRRect(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.09,
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 7, 7, 42),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Browse tab
            _NavItem(
              icon: Icons.home,
              label: 'Browse',
              isSelected: selectedIndex == 0,
              onTap: () => ref.read(selectedTabIndexProvider.notifier).state = 0,
            ),
            // My Listings tab
            _NavItem(
              icon: Icons.library_books,
              label: 'My Listings',
              isSelected: selectedIndex == 1,
              onTap: () => ref.read(selectedTabIndexProvider.notifier).state = 1,
            ),
            // Chats tab
            _NavItem(
              icon: Icons.message,
              label: 'Chats',
              isSelected: selectedIndex == 2,
              onTap: () => ref.read(selectedTabIndexProvider.notifier).state = 2,
            ),
            // Settings tab
            _NavItem(
              icon: Icons.settings,
              label: 'Settings',
              isSelected: selectedIndex == 3,
              onTap: () => ref.read(selectedTabIndexProvider.notifier).state = 3,
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual navigation item widget
/// 
/// Displays an icon and label. Selected items are highlighted:
/// - White color (vs gray for unselected)
/// - Larger icon (26px vs 24px)
/// - Bold text (vs normal weight)
class _NavItem extends StatelessWidget {
  /// Icon to display
  final IconData icon;
  
  /// Label text below icon
  final String label;
  
  /// Whether this tab is currently selected
  final bool isSelected;
  
  /// Callback when tab is tapped
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon - larger and white if selected
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : const Color.fromARGB(255, 150, 150, 150),
              size: isSelected ? 26 : 24,
            ),
            const SizedBox(height: 4),
            // Label - bold and white if selected
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : const Color.fromARGB(255, 150, 150, 150),
                fontSize: isSelected ? 14 : 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

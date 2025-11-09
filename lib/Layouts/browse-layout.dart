import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookswap/Services/book_providers.dart';
import 'package:bookswap/Firebase/auth_providers.dart';
import 'package:bookswap/Models/book.dart';
import 'package:bookswap/Services/swap_providers.dart';

/// Browse Layout - Shows all book listings with swap functionality
class BrowseLayout extends ConsumerWidget {
  const BrowseLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allBooksAsync = ref.watch(allBooksProvider);
    final currentUserAsync = ref.watch(currentUserStreamProvider);

    return currentUserAsync.when(
      data: (currentUser) {
        return allBooksAsync.when(
          data: (books) {
            // Filter out user's own books and books that are not available for swap
            // A book is available for swap when swapStatus is null
            final filteredBooks = currentUser != null
                ? books.where((book) => 
                    book.userId != currentUser.uid && 
                    book.swapStatus == null).toList()
                : books.where((book) => book.swapStatus == null).toList();

        if (filteredBooks.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.book_outlined,
                  size: 80,
                  color: Color.fromARGB(255, 150, 150, 150),
                ),
                SizedBox(height: 16),
                Text(
                  'No books available for swap yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color.fromARGB(255, 100, 100, 100),
                  ),
                ),
              ],
            ),
          );
        }

            return ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: filteredBooks.length,
              itemBuilder: (context, index) {
                final book = filteredBooks[index];
                return _BookCard(book: book, currentUserId: currentUser?.uid);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Error: $error'),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => allBooksAsync.when(
        data: (books) {
          // Filter out books that are not available for swap
          final availableBooks = books.where((book) => book.swapStatus == null).toList();
          if (availableBooks.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 80,
                    color: Color.fromARGB(255, 150, 150, 150),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No books available yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color.fromARGB(255, 100, 100, 100),
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: availableBooks.length,
            itemBuilder: (context, index) {
              final book = availableBooks[index];
              return _BookCard(book: book, currentUserId: null);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}

/// Book Card Widget for Browse Screen
class _BookCard extends ConsumerWidget {
  final Book book;
  final String? currentUserId;

  const _BookCard({
    required this.book,
    this.currentUserId,
  });

  String _getDaysAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    final days = difference.inDays;
    
    if (days == 0) {
      return 'Today';
    } else if (days == 1) {
      return '1 day ago';
    } else {
      return '$days days ago';
    }
  }

  Future<void> _requestSwap(BuildContext context, WidgetRef ref) async {
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to request a book swap'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Book Swap'),
        content: Text('Are you sure you want to request a swap for "${book.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 5, 22, 46),
              foregroundColor: Colors.white,
            ),
            child: const Text('Request Swap'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading indicator
    if (!context.mounted) return;
    
    // Store a reference to the navigator before showing dialog
    final navigator = Navigator.of(context);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false, // Prevent back button from closing
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );

    try {
      debugPrint('Starting swap request for book: ${book.id}');
      final swapService = ref.read(swapServiceProvider);
      
      debugPrint('Creating swap offer...');
      await swapService.createSwapOffer(
        bookId: book.id,
        book: book,
      );
      debugPrint('Swap offer created successfully');

      // Close loading dialog - use navigator reference even if context is unmounted
      try {
        debugPrint('Closing loading dialog...');
        navigator.pop();
        debugPrint('Dialog closed');
      } catch (e) {
        debugPrint('Error closing dialog: $e');
      }
      
      // Small delay to ensure dialog is closed before showing snackbar
      await Future.delayed(const Duration(milliseconds: 150));
      
      // Try to show snackbar - use navigator context to avoid deactivated widget issues
      try {
        if (navigator.context.mounted) {
          final scaffoldMessenger = ScaffoldMessenger.maybeOf(navigator.context);
          if (scaffoldMessenger != null) {
            debugPrint('📢 Showing success message');
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('Swap request sent for "${book.title}"'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            debugPrint('Could not find ScaffoldMessenger');
          }
        } else {
          debugPrint('Navigator context not mounted');
        }
      } catch (e) {
        debugPrint('Error showing snackbar: $e');
      }
    } catch (e, stackTrace) {
      debugPrint('Error creating swap: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Close loading dialog - use navigator reference even if context is unmounted
      try {
        debugPrint('Closing loading dialog (error case)...');
        navigator.pop();
        debugPrint('Dialog closed (error case)');
      } catch (e) {
        debugPrint('Error closing dialog: $e');
      }
      
      // Small delay to ensure dialog is closed before showing snackbar
      await Future.delayed(const Duration(milliseconds: 150));
      
      // Try to show snackbar - use navigator context to avoid deactivated widget issues
      try {
        if (navigator.context.mounted) {
          final scaffoldMessenger = ScaffoldMessenger.maybeOf(navigator.context);
          if (scaffoldMessenger != null) {
            debugPrint('📢 Showing error message');
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          } else {
            debugPrint('Could not find ScaffoldMessenger for error');
          }
        } else {
          debugPrint('Navigator context not mounted for error');
        }
      } catch (e2) {
        debugPrint('Error showing error snackbar: $e2');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _requestSwap(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color.fromARGB(255, 230, 230, 230),
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover Image
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                book.coverImageUrl,
                width: 60,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 90,
                    color: Colors.grey[300],
                    child: const Icon(Icons.book, size: 30),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            // Book Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${book.author}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(255, 100, 100, 100),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    book.condition.displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(255, 100, 100, 100),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 14,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getDaysAgo(book.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

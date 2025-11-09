import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../services/firestore_service.dart';
import '../utils/image_helper.dart';
import '../providers/book_provider.dart';
import '../providers/swap_provider.dart';
import 'edit_book_screen.dart';

/// Book Details Screen
class BookDetailsScreen extends StatelessWidget {
  final Book book;

  const BookDetailsScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser?.uid == book.ownerId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Details'),
        backgroundColor: const Color(0xFF2C2855),
        foregroundColor: Colors.white,
        actions: [
          if (isOwner)
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
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
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
                  _showDeleteConfirmation(context, book);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover image section
            Hero(
              tag: 'book_${book.id}',
              child: BookCoverImage(
                imageUrl: book.imageUrl,
                width: double.infinity,
                height: 400,
                fit: BoxFit.cover,
              ),
            ),

            // Book information section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book title
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2855),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Author name
                  Text(
                    'by ${book.author}',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Condition and status badges
                  Row(
                    children: [
                      _buildBadge(
                        book.condition,
                        _getConditionColor(book.condition),
                      ),
                      const SizedBox(width: 12),
                      _buildBadge(
                        book.status,
                        book.status == 'available' ? Colors.green : Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Divider(),
                  const SizedBox(height: 16),

                  // Swap preference section
                  const Text(
                    'Owner is looking to swap for:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5C344).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFF5C344),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      book.swapFor,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Divider(),
                  const SizedBox(height: 16),

                  // Owner information section
                  const Text(
                    'Listed by:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF2C2855),
                        child: Text(
                          book.ownerEmail[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.ownerEmail,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Posted ${_formatDate(book.createdAt)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
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
      // Bottom action button for non-owners
      bottomNavigationBar: !isOwner && book.status == 'available'
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  _showSwapOfferDialog(context, book);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C2855),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Offer a Swap',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            )
          : null,
    );
  }

  /// Building badge widget
  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Getting color based on book condition
  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'new':
        return Colors.green;
      case 'like new':
        return Colors.blue;
      case 'good':
        return Colors.orange;
      case 'fair':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  /// Formatting date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Showing swap offer dialog - letting user choose which book to offer
  void _showSwapOfferDialog(BuildContext context, Book requestedBook) async {
    // Getting current user's books
    final myBooks = context.read<BookProvider>().myBooks;

    if (myBooks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You need to post a book first before making swap offers!',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Showing dialog to select which book to offer
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select Your Book to Offer'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You want: "${requestedBook.title}"',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Owner is looking for: ${requestedBook.swapFor}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const Divider(height: 24),
              const Text(
                'Choose a book to offer in exchange:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: myBooks.length,
                  itemBuilder: (context, index) {
                    final myBook = myBooks[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.book,
                          color: Color(0xFF2C2855),
                        ),
                        title: Text(
                          myBook.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('by ${myBook.author}'),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () {
                          Navigator.pop(dialogContext);
                          _confirmSwapOffer(context, myBook, requestedBook);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Confirming swap offer
  void _confirmSwapOffer(
    BuildContext context,
    Book offeredBook,
    Book requestedBook,
  ) {
    // Capture the provider reference before opening the dialog
    final swapProvider = context.read<SwapProvider>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Swap Offer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You are offering:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              offeredBook.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Icon(Icons.swap_horiz, size: 32, color: Color(0xFF2C2855)),
            const SizedBox(height: 16),
            const Text(
              'In exchange for:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              requestedBook.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2C2855),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Create swap offer using the captured provider
                await swapProvider.createSwapOffer(
                  recipientId: requestedBook.ownerId,
                  recipientEmail: requestedBook.ownerEmail,
                  offeredBookId: offeredBook.id,
                  offeredBookTitle: offeredBook.title,
                  requestedBookId: requestedBook.id,
                  requestedBookTitle: requestedBook.title,
                );

                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Your offer sent, waiting for approval 📩'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to send offer: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C2855),
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Offer'),
          ),
        ],
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
                // Deleting from Firestore
                await FirestoreService().deleteBook(book.id);

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext); // Close dialog
                  // Try to pop the details screen if possible, but avoid popping to root
                  await Navigator.of(context).maybePop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Book deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

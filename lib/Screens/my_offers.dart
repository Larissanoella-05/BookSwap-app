import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookswap/Services/swap_providers.dart';
import 'package:bookswap/Services/chat_providers.dart';
import 'package:bookswap/Firebase/auth_providers.dart';
import 'package:bookswap/Models/swap.dart';
import 'package:bookswap/Services/book_providers.dart';
import 'package:bookswap/Screens/chat_detail.dart';

/// My Offers Screen - Shows swap offers (both sent and received)
class MyOffersScreen extends ConsumerStatefulWidget {
  const MyOffersScreen({super.key});

  @override
  ConsumerState<MyOffersScreen> createState() => _MyOffersScreenState();
}

class _MyOffersScreenState extends ConsumerState<MyOffersScreen> {
  int _selectedSegment = 0; // 0 = Sent, 1 = Received

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserStreamProvider);

    return currentUserAsync.when(
      data: (currentUser) {
        if (currentUser == null) {
          return const Center(
            child: Text('Please log in to view your offers'),
          );
        }

    return Container(
      color: const Color.fromARGB(255, 248, 248, 248),
      child: Column(
        children: [
          // Segmented Control for Sent/Received
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedSegment = 0;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedSegment == 0
                            ? const Color.fromARGB(255, 250, 174, 22)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Sent',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _selectedSegment == 0
                              ? Colors.white
                              : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedSegment = 1;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedSegment == 1
                            ? const Color.fromARGB(255, 250, 174, 22)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Received',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _selectedSegment == 1
                              ? Colors.white
                              : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Content based on selected segment
        Expanded(
          child: _selectedSegment == 0
              ? _SentOffersTab(userId: currentUser.uid)
              : _ReceivedOffersTab(userId: currentUser.uid),
        ),
        ],
      ),
    );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
}

/// Sent Offers Tab - Shows swaps user initiated
class _SentOffersTab extends ConsumerWidget {
  final String userId;

  const _SentOffersTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myOffersAsync = ref.watch(myOffersProvider(userId));

    return myOffersAsync.when(
      data: (swaps) {
        if (swaps.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.swap_horiz_outlined,
                  size: 80,
                  color: Color.fromARGB(255, 150, 150, 150),
                ),
                SizedBox(height: 16),
                Text(
                  'No swap offers sent',
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
          padding: const EdgeInsets.all(16),
          itemCount: swaps.length,
          itemBuilder: (context, index) {
            final swap = swaps[index];
            return _SwapCard(swap: swap, isReceived: false);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) {
        String errorMessage = error.toString();
        if (errorMessage.contains('index') || errorMessage.contains('FAILED_PRECONDITION')) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.hourglass_empty,
                    size: 60,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Indexes are building...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Firestore indexes are being created. This usually takes 2-5 minutes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(myOffersProvider(userId));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Error loading swaps',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(myOffersProvider(userId));
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Received Offers Tab - Shows swaps user received
class _ReceivedOffersTab extends ConsumerWidget {
  final String userId;

  const _ReceivedOffersTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receivedOffersAsync = ref.watch(receivedOffersProvider(userId));

    return receivedOffersAsync.when(
      data: (swaps) {
        if (swaps.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 80,
                  color: Color.fromARGB(255, 150, 150, 150),
                ),
                SizedBox(height: 16),
                Text(
                  'No swap offers received',
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
          padding: const EdgeInsets.all(16),
          itemCount: swaps.length,
          itemBuilder: (context, index) {
            final swap = swaps[index];
            return _SwapCard(swap: swap, isReceived: true);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) {
        String errorMessage = error.toString();
        if (errorMessage.contains('index') || errorMessage.contains('FAILED_PRECONDITION')) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.hourglass_empty,
                    size: 60,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Indexes are building...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Firestore indexes are being created. This usually takes 2-5 minutes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(receivedOffersProvider(userId));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Error loading swaps',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(receivedOffersProvider(userId));
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Swap Card Widget
class _SwapCard extends ConsumerWidget {
  final Swap swap;
  final bool isReceived;

  const _SwapCard({
    required this.swap,
    required this.isReceived,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swapService = ref.watch(swapServiceProvider);
    final bookAsync = ref.watch(bookByIdProvider(swap.bookId));

    return bookAsync.when(
      data: (book) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book Cover
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${book.author}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color.fromARGB(255, 100, 100, 100),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(swap.status),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            swap.status.displayName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                isReceived
                    ? 'Requested by: ${swap.requesterEmail}'
                    : 'Owner: ${swap.ownerEmail}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color.fromARGB(255, 150, 150, 150),
                ),
              ),
              if (isReceived && swap.status == SwapStatus.pending) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await swapService.acceptSwap(swap.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Swap accepted!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Accept'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          try {
                            await swapService.rejectSwap(swap.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Swap rejected'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                  ],
                ),
              ] else if (!isReceived && swap.status == SwapStatus.pending) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Cancel Swap'),
                              content: const Text('Are you sure you want to cancel this swap request?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('No'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Yes'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            try {
                              await swapService.cancelSwap(swap.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Swap cancelled'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('Cancel Swap'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final currentUser = ref.read(currentUserProvider);
                          if (currentUser == null) return;
                          
                          try {
                            final chatService = ref.read(chatServiceProvider);
                            
                            // Create or get existing chat with the book owner
                            final chat = await chatService.createChat(
                              userId1: currentUser.uid,
                              userId2: swap.ownerId,
                              user1Email: currentUser.email,
                              user2Email: swap.ownerEmail,
                              user1Name: currentUser.displayName,
                              user1PhotoURL: currentUser.photoURL,
                            );
                            
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatDetailScreen(chat: chat),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error starting chat: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.message, size: 18),
                        label: const Text('Message Owner'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                          side: const BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('Error: $error')),
    );
  }

  Color _getStatusColor(SwapStatus status) {
    switch (status) {
      case SwapStatus.pending:
        return Colors.orange;
      case SwapStatus.accepted:
        return Colors.green;
      case SwapStatus.rejected:
        return Colors.red;
    }
  }
}


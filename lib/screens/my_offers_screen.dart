import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/swap_provider.dart';
import '../models/swap_offer.dart';
import '../services/chat_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'chat_screen.dart';

/// My Offers Screen - Shows sent and received swap offers
class MyOffersScreen extends StatefulWidget {
  const MyOffersScreen({super.key});

  @override
  State<MyOffersScreen> createState() => _MyOffersScreenState();
}

class _MyOffersScreenState extends State<MyOffersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Starting to listen to offers when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SwapProvider>().listenToSentOffers();
      context.read<SwapProvider>().listenToReceivedOffers();
      context.read<SwapProvider>().listenToPendingOffersCount();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Swap Offers'),
        backgroundColor: const Color(0xFF2C2855),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Removing back button
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFF5C344),
          labelColor: const Color(0xFFF5C344),
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send),
                  const SizedBox(width: 8),
                  const Text('Sent'),
                ],
              ),
            ),
            Tab(
              child: Consumer<SwapProvider>(
                builder: (context, swapProvider, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inbox),
                      const SizedBox(width: 8),
                      const Text('Received'),
                      if (swapProvider.pendingOffersCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${swapProvider.pendingOffersCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [SentOffersTab(), ReceivedOffersTab()],
      ),
    );
  }
}

/// Tab showing sent offers
class SentOffersTab extends StatelessWidget {
  const SentOffersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SwapProvider>(
      builder: (context, swapProvider, child) {
        if (swapProvider.sentOffers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No sent offers yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Browse books and make swap offers!',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: swapProvider.sentOffers.length,
          itemBuilder: (context, index) {
            final offer = swapProvider.sentOffers[index];
            return SentOfferCard(offer: offer);
          },
        );
      },
    );
  }
}

/// Tab showing received offers
class ReceivedOffersTab extends StatelessWidget {
  const ReceivedOffersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SwapProvider>(
      builder: (context, swapProvider, child) {
        if (swapProvider.receivedOffers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No received offers yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'When someone wants to swap with you, it will appear here',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: swapProvider.receivedOffers.length,
          itemBuilder: (context, index) {
            final offer = swapProvider.receivedOffers[index];
            return ReceivedOfferCard(offer: offer);
          },
        );
      },
    );
  }
}

/// Card for sent offers
class SentOfferCard extends StatelessWidget {
  final SwapOffer offer;

  const SentOfferCard({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(offer.status),
                Text(
                  timeago.format(offer.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Offer details
            Text(
              'You offered:',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              offer.offeredBookTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),

            const Divider(),
            const SizedBox(height: 8),

            Text(
              'For:',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              offer.requestedBookTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Owner: ${offer.recipientEmail}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),

            // Action buttons
            const SizedBox(height: 12),
            if (offer.status == 'pending')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _cancelOffer(context, offer),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel Offer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            if (offer.status == 'accepted')
              SizedBox(
                width: double.infinity,
                child: StreamBuilder<int>(
                  stream: ChatService().getUnreadCountStream(offer.id),
                  builder: (context, snapshot) {
                    final unreadCount = snapshot.data ?? 0;
                    return ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(swapOffer: offer),
                          ),
                        );
                      },
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.chat),
                          if (unreadCount > 0)
                            Positioned(
                              right: -8,
                              top: -8,
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
                                  '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      label: const Text('Chat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C2855),
                        foregroundColor: Colors.white,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _cancelOffer(BuildContext context, SwapOffer offer) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Offer'),
        content: const Text('Are you sure you want to cancel this swap offer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await context.read<SwapProvider>().cancelOffer(offer.id);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Offer cancelled'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to cancel: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    String text;

    switch (status) {
      case 'accepted':
        color = Colors.green;
        icon = Icons.check_circle;
        text = 'Accepted';
        break;
      case 'rejected':
        color = Colors.red;
        icon = Icons.cancel;
        text = 'Rejected';
        break;
      default:
        color = Colors.orange;
        icon = Icons.pending;
        text = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card for received offers
class ReceivedOfferCard extends StatelessWidget {
  final SwapOffer offer;

  const ReceivedOfferCard({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(offer.status),
                Text(
                  timeago.format(offer.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              '${offer.senderEmail} wants to swap:',
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
            const SizedBox(height: 8),

            // What they're offering
            Text(
              offer.offeredBookTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),

            const Divider(),
            const SizedBox(height: 8),

            Text(
              'For your book:',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              offer.requestedBookTitle,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2C2855),
              ),
            ),

            // Action buttons
            const SizedBox(height: 16),
            if (offer.status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptOffer(context, offer),
                      icon: const Icon(Icons.check),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectOffer(context, offer),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            if (offer.status == 'accepted')
              SizedBox(
                width: double.infinity,
                child: StreamBuilder<int>(
                  stream: ChatService().getUnreadCountStream(offer.id),
                  builder: (context, snapshot) {
                    final unreadCount = snapshot.data ?? 0;
                    return ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(swapOffer: offer),
                          ),
                        );
                      },
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.chat),
                          if (unreadCount > 0)
                            Positioned(
                              right: -8,
                              top: -8,
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
                                  '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      label: const Text('Chat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C2855),
                        foregroundColor: Colors.white,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _acceptOffer(BuildContext context, SwapOffer offer) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Accept Swap Offer'),
        content: Text(
          'Accept swap offer?\n\n'
          'You\'ll exchange "${offer.requestedBookTitle}" '
          'for "${offer.offeredBookTitle}"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await context.read<SwapProvider>().acceptOffer(offer.id);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Swap offer accepted! 🎉'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to accept: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  void _rejectOffer(BuildContext context, SwapOffer offer) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Swap Offer'),
        content: const Text('Are you sure you want to reject this swap offer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await context.read<SwapProvider>().rejectOffer(offer.id);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Offer rejected'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to reject: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    String text;

    switch (status) {
      case 'accepted':
        color = Colors.green;
        icon = Icons.check_circle;
        text = 'Accepted';
        break;
      case 'rejected':
        color = Colors.red;
        icon = Icons.cancel;
        text = 'Rejected';
        break;
      default:
        color = Colors.orange;
        icon = Icons.pending;
        text = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

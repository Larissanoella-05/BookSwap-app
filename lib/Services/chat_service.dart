import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _messagesCollection =>
      _firestore.collection('chat_messages');

  // Sending a message
  Future<void> sendMessage({
    required String swapOfferId,
    required String message,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final chatMessage = ChatMessage(
      id: '',
      swapOfferId: swapOfferId,
      senderId: user.uid,
      senderEmail: user.email ?? '',
      message: message.trim(),
      timestamp: DateTime.now(),
      isRead: false,
    );

    await _messagesCollection.add(chatMessage.toMap());
  }

  // Getting messages for swap offers
  Stream<List<ChatMessage>> getMessagesStream(String swapOfferId) {
    return _messagesCollection
        .where('swapOfferId', isEqualTo: swapOfferId)
        .snapshots()
        .map(
          (snapshot) {
            final messages = snapshot.docs
                .map((doc) => ChatMessage.fromFirestore(doc))
                .toList();
            // Sort in memory instead of using orderBy
            messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            return messages;
          },
        );
  }

  // Marking messages as read
  Future<void> markMessagesAsRead(String swapOfferId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final unreadMessages = await _messagesCollection
        .where('swapOfferId', isEqualTo: swapOfferId)
        .where('senderId', isNotEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // Getting the unread messages count for a specific swap offer
  Stream<int> getUnreadCountStream(String swapOfferId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _messagesCollection
        .where('swapOfferId', isEqualTo: swapOfferId)
        .where('senderId', isNotEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Getting the total unread messages count across all chats
  Stream<int> getTotalUnreadCountStream() async* {
    final user = _auth.currentUser;
    if (user == null) {
      yield 0;
      return;
    }

    // First, get all accepted swap offers where current user is involved
    await for (var swapSnapshot
        in _firestore
            .collection('swap_offers')
            .where('status', isEqualTo: 'accepted')
            .snapshots()) {
      // Filter swap offers where current user is sender or recipient
      final mySwapOffers = swapSnapshot.docs
          .where((doc) {
            final data = doc.data();
            return data['senderId'] == user.uid ||
                data['recipientId'] == user.uid;
          })
          .map((doc) => doc.id)
          .toList();

      if (mySwapOffers.isEmpty) {
        yield 0;
        continue;
      }

      // Get unread messages for these swap offers
      final messagesSnapshot = await _messagesCollection
          .where('swapOfferId', whereIn: mySwapOffers)
          .where('senderId', isNotEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      yield messagesSnapshot.docs.length;
    }
  }

  // Deleting all messages that have been swapped
  Future<void> deleteMessagesForSwap(String swapOfferId) async {
    final messages = await _messagesCollection
        .where('swapOfferId', isEqualTo: swapOfferId)
        .get();

    final batch = _firestore.batch();
    for (var doc in messages.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

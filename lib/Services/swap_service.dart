import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/swap_offer.dart';
import 'firestore_service.dart';

class SwapService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  CollectionReference get _swapOffersCollection =>
      _firestore.collection('swap_offers');

  // Creating new swap offer
  Future<void> createSwapOffer({
    required String recipientId,
    required String recipientEmail,
    required String offeredBookId,
    required String offeredBookTitle,
    required String requestedBookId,
    required String requestedBookTitle,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be logged in to create swap offer');
    }

    final swapOffer = SwapOffer(
      id: '',
      senderId: currentUser.uid,
      senderEmail: currentUser.email ?? '',
      recipientId: recipientId,
      recipientEmail: recipientEmail,
      offeredBookId: offeredBookId,
      offeredBookTitle: offeredBookTitle,
      requestedBookId: requestedBookId,
      requestedBookTitle: requestedBookTitle,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    await _swapOffersCollection.add(swapOffer.toFirestore());
  }

  // Getting offers I sent
  Stream<List<SwapOffer>> getSentOffers() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _swapOffersCollection
        .where('senderId', isEqualTo: currentUser.uid)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => SwapOffer.fromFirestore(doc)).toList(),
        );
  }

  // Getting offers I received
  Stream<List<SwapOffer>> getReceivedOffers() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _swapOffersCollection
        .where('recipientId', isEqualTo: currentUser.uid)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => SwapOffer.fromFirestore(doc)).toList(),
        );
  }

  // Accepting swap and delete both books
  Future<void> acceptOffer(String offerId) async {
    final offerDoc = await _swapOffersCollection.doc(offerId).get();

    if (!offerDoc.exists) {
      throw Exception('Swap offer not found');
    }

    final offer = SwapOffer.fromFirestore(offerDoc);

    await _swapOffersCollection.doc(offerId).update({
      'status': 'accepted',
      'respondedAt': Timestamp.now(),
    });

    // Deleting both books
    try {
      await _firestoreService.deleteBook(offer.offeredBookId);
      await _firestoreService.deleteBook(offer.requestedBookId);
    } catch (e) {
      // Error deleting books - swap will still be marked as complete
    }
  }

  // Rejecting swap offers
  Future<void> rejectOffer(String offerId) async {
    await _swapOffersCollection.doc(offerId).update({
      'status': 'rejected',
      'respondedAt': Timestamp.now(),
    });
  }

  // Canceling swap offer
  Future<void> cancelOffer(String offerId) async {
    await _swapOffersCollection.doc(offerId).delete();
  }

  // Counting pending offers for the notification badge
  Stream<int> getPendingReceivedOffersCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(0);

    return _swapOffersCollection
        .where('recipientId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}

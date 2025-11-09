import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:bookswap/Models/swap.dart';
import 'package:bookswap/Models/book.dart';
import 'package:bookswap/Services/chat_service.dart';

/// Service class for managing swap offers (CRUD operations)
class SwapService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ChatService _chatService = ChatService();

  // Collection name in Firestore
  static const String _collectionName = 'swaps';

  /// CREATE: Create a new swap offer
  /// 
  /// Steps:
  /// 1. Get current user
  /// 2. Get book details
  /// 3. Create swap document in Firestore
  /// 4. Update book status to 'pending'
  Future<Swap> createSwapOffer({
    required String bookId,
    required Book book,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw 'You must be logged in to create a swap offer';
    }

    // Check if user is trying to swap their own book
    if (book.userId == user.uid) {
      throw 'You cannot swap your own book';
    }

    // Check if book already has a pending swap
    if (book.swapStatus == 'pending') {
      throw 'This book already has a pending swap offer';
    }

    try {
      debugPrint('SwapService: Starting swap creation');
      final now = DateTime.now();
      final swapData = {
        'bookId': bookId,
        'requesterId': user.uid,
        'requesterEmail': user.email ?? '',
        'ownerId': book.userId,
        'ownerEmail': book.userEmail,
        'status': SwapStatus.pending.displayName,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      // Create swap document
      debugPrint('SwapService: Creating swap document in Firestore...');
      final DocumentReference docRef = await _firestore
          .collection(_collectionName)
          .add(swapData);
      debugPrint('SwapService: Swap document created with ID: ${docRef.id}');

      // Update book status to pending
      debugPrint('SwapService: Updating book status to pending...');
      await _firestore
          .collection('books')
          .doc(bookId)
          .update({
        'swapStatus': 'pending',
        'updatedAt': Timestamp.fromDate(now),
      });
      debugPrint('SwapService: Book status updated to pending');

      // Create a chat between the two users for this swap
      // Chat is created when swap offer is initiated (as per assignment requirement)
      // Run chat creation in background to avoid blocking
      debugPrint('💬 SwapService: Starting chat creation (non-blocking)...');
      _chatService.createChat(
        userId1: user.uid,
        userId2: book.userId,
        swapId: docRef.id,
        user1Email: user.email,
        user2Email: book.userEmail,
        user1Name: user.displayName,
        user1PhotoURL: user.photoURL,
      ).then((_) {
        debugPrint('SwapService: Chat created successfully');
      }).catchError((e) {
        // Log error but don't fail the swap creation
        // Chat creation is optional - users can still chat later
        debugPrint('⚠️ SwapService: Chat creation failed (may already exist): $e');
      });

      // Note: Notifications for swap requests are handled by NotificationListener
      // which watches for new swaps for the book owner

      // Return Swap object immediately without extra network call
      // We construct it from the data we already have
      debugPrint('SwapService: Returning Swap object');
      return Swap(
        id: docRef.id,
        bookId: bookId,
        requesterId: user.uid,
        requesterEmail: user.email ?? '',
        ownerId: book.userId,
        ownerEmail: book.userEmail,
        status: SwapStatus.pending,
        createdAt: now,
        updatedAt: now,
      );
    } on FirebaseException catch (e) {
      throw 'Failed to create swap offer: ${e.message}';
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  /// READ: Get all swaps initiated by a user (swaps they requested)
  Stream<List<Swap>> getMyOffers(String userId) {
    try {
      return _firestore
          .collection(_collectionName)
          .where('requesterId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => Swap.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      throw 'Failed to fetch my offers: $e';
    }
  }

  /// READ: Get all swaps received by a user (swaps for their books)
  Stream<List<Swap>> getReceivedOffers(String userId) {
    try {
      return _firestore
          .collection(_collectionName)
          .where('ownerId', isEqualTo: userId)
          .where('status', isEqualTo: SwapStatus.pending.displayName)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => Swap.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      // If index is not ready, return empty list instead of error
      if (e.toString().contains('index') || e.toString().contains('FAILED_PRECONDITION')) {
        debugPrint('Index not ready yet, returning empty list');
        return Stream.value([]);
      }
      throw 'Failed to fetch received offers: $e';
    }
  }

  /// READ: Get all swaps for a specific book
  Stream<List<Swap>> getSwapsForBook(String bookId) {
    try {
      return _firestore
          .collection(_collectionName)
          .where('bookId', isEqualTo: bookId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => Swap.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      throw 'Failed to fetch swaps for book: $e';
    }
  }

  /// READ: Get a single swap by ID
  Future<Swap> getSwapById(String swapId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(swapId)
          .get();

      if (!doc.exists) {
        throw 'Swap not found';
      }

      return Swap.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw 'Failed to fetch swap: ${e.message}';
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  /// UPDATE: Accept a swap offer
  /// 
  /// Only the book owner can accept a swap
  Future<void> acceptSwap(String swapId) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw 'You must be logged in to accept a swap';
    }

    try {
      // Get swap document
      final swapDoc = await _firestore
          .collection(_collectionName)
          .doc(swapId)
          .get();

      if (!swapDoc.exists) {
        throw 'Swap not found';
      }

      final swap = Swap.fromFirestore(swapDoc);

      // Check if user is the owner
      if (swap.ownerId != user.uid) {
        throw 'Only the book owner can accept a swap';
      }

      // Check if swap is still pending
      if (swap.status != SwapStatus.pending) {
        throw 'This swap has already been ${swap.status.displayName.toLowerCase()}';
      }

      final now = DateTime.now();

      // Update swap status to accepted
      await _firestore
          .collection(_collectionName)
          .doc(swapId)
          .update({
        'status': SwapStatus.accepted.displayName,
        'updatedAt': Timestamp.fromDate(now),
      });

      // Update book status to swapped
      await _firestore
          .collection('books')
          .doc(swap.bookId)
          .update({
        'swapStatus': 'swapped',
        'updatedAt': Timestamp.fromDate(now),
      });

      // Reject all other pending swaps for this book
      final otherSwaps = await _firestore
          .collection(_collectionName)
          .where('bookId', isEqualTo: swap.bookId)
          .where('status', isEqualTo: SwapStatus.pending.displayName)
          .where(FieldPath.documentId, isNotEqualTo: swapId)
          .get();

      final batch = _firestore.batch();
      for (var doc in otherSwaps.docs) {
        batch.update(doc.reference, {
          'status': SwapStatus.rejected.displayName,
          'updatedAt': Timestamp.fromDate(now),
        });
      }
      await batch.commit();

      // Create a chat between the two users for this swap
      try {
        await _chatService.createChat(
          userId1: swap.requesterId,
          userId2: swap.ownerId,
          swapId: swapId,
        );
      } catch (e) {
        // Log error but don't fail the swap acceptance
        // Chat creation is optional - users can still chat later
      }
    } on FirebaseException catch (e) {
      throw 'Failed to accept swap: ${e.message}';
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  /// UPDATE: Reject a swap offer
  /// 
  /// Only the book owner can reject a swap
  Future<void> rejectSwap(String swapId) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw 'You must be logged in to reject a swap';
    }

    try {
      // Get swap document
      final swapDoc = await _firestore
          .collection(_collectionName)
          .doc(swapId)
          .get();

      if (!swapDoc.exists) {
        throw 'Swap not found';
      }

      final swap = Swap.fromFirestore(swapDoc);

      // Check if user is the owner
      if (swap.ownerId != user.uid) {
        throw 'Only the book owner can reject a swap';
      }

      // Check if swap is still pending
      if (swap.status != SwapStatus.pending) {
        throw 'This swap has already been ${swap.status.displayName.toLowerCase()}';
      }

      final now = DateTime.now();

      // Update swap status to rejected
      await _firestore
          .collection(_collectionName)
          .doc(swapId)
          .update({
        'status': SwapStatus.rejected.displayName,
        'updatedAt': Timestamp.fromDate(now),
      });

      // Update book status back to available (if no other pending swaps)
      final pendingSwaps = await _firestore
          .collection(_collectionName)
          .where('bookId', isEqualTo: swap.bookId)
          .where('status', isEqualTo: SwapStatus.pending.displayName)
          .get();

      if (pendingSwaps.docs.isEmpty) {
        await _firestore
            .collection('books')
            .doc(swap.bookId)
            .update({
          'swapStatus': null,
          'updatedAt': Timestamp.fromDate(now),
        });
      }
    } on FirebaseException catch (e) {
      throw 'Failed to reject swap: ${e.message}';
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  /// DELETE: Cancel a swap offer (only requester can cancel)
  Future<void> cancelSwap(String swapId) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw 'You must be logged in to cancel a swap';
    }

    try {
      // Get swap document
      final swapDoc = await _firestore
          .collection(_collectionName)
          .doc(swapId)
          .get();

      if (!swapDoc.exists) {
        throw 'Swap not found';
      }

      final swap = Swap.fromFirestore(swapDoc);

      // Check if user is the requester
      if (swap.requesterId != user.uid) {
        throw 'Only the requester can cancel a swap';
      }

      // Check if swap is still pending
      if (swap.status != SwapStatus.pending) {
        throw 'Cannot cancel a swap that has been ${swap.status.displayName.toLowerCase()}';
      }

      final now = DateTime.now();

      // Delete swap document
      await _firestore
          .collection(_collectionName)
          .doc(swapId)
          .delete();

      // Update book status back to available (if no other pending swaps)
      final pendingSwaps = await _firestore
          .collection(_collectionName)
          .where('bookId', isEqualTo: swap.bookId)
          .where('status', isEqualTo: SwapStatus.pending.displayName)
          .get();

      if (pendingSwaps.docs.isEmpty) {
        await _firestore
            .collection('books')
            .doc(swap.bookId)
            .update({
          'swapStatus': null,
          'updatedAt': Timestamp.fromDate(now),
        });
      }
    } on FirebaseException catch (e) {
      throw 'Failed to cancel swap: ${e.message}';
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }
}


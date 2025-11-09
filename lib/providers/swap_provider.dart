import 'package:flutter/foundation.dart';
import '../models/swap_offer.dart';
import '../services/swap_service.dart';

/// Provider class that manages swap offer state and operations
/// Handles creating, accepting, rejecting swap offers with real-time updates
class SwapProvider with ChangeNotifier {
  // Service for swap-related Firestore operations
  final SwapService _swapService = SwapService();

  // Private state variables
  List<SwapOffer> _sentOffers = [];     // Offers sent by current user
  List<SwapOffer> _receivedOffers = []; // Offers received by current user
  int _pendingOffersCount = 0;          // Count of pending received offers
  bool _isLoading = false;              // Loading state for UI
  String? _error;                       // Error message if operations fail

  // Public getters for accessing state from UI
  /// Returns offers sent by the current user
  List<SwapOffer> get sentOffers => _sentOffers;
  
  /// Returns offers received by the current user
  List<SwapOffer> get receivedOffers => _receivedOffers;
  
  /// Returns count of pending offers for notification badge
  int get pendingOffersCount => _pendingOffersCount;
  
  /// Returns current loading state
  bool get isLoading => _isLoading;
  
  /// Returns current error message if any
  String? get error => _error;

  /// Sets up real-time listener for offers sent by current user
  /// Used in My Offers screen "Sent" tab
  void listenToSentOffers() {
    _swapService.getSentOffers().listen(
      (offers) {
        _sentOffers = offers;
        _error = null;
        // Notify UI to rebuild with updated sent offers
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load sent offers: $error';
        notifyListeners();
      },
    );
  }

  /// Sets up real-time listener for offers received by current user
  /// Used in My Offers screen "Received" tab
  void listenToReceivedOffers() {
    _swapService.getReceivedOffers().listen(
      (offers) {
        _receivedOffers = offers;
        _error = null;
        // Notify UI to rebuild with updated received offers
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load received offers: $error';
        notifyListeners();
      },
    );
  }

  /// Sets up real-time listener for pending offers count
  /// Used for notification badge on My Offers tab
  void listenToPendingOffersCount() {
    _swapService.getPendingReceivedOffersCount().listen((count) {
      _pendingOffersCount = count;
      // Update notification badge in real-time
      notifyListeners();
    });
  }

  /// Creates a new swap offer between two users
  /// Called when user taps "Offer a Swap" and selects their book
  Future<void> createSwapOffer({
    required String recipientId,
    required String recipientEmail,
    required String offeredBookId,
    required String offeredBookTitle,
    required String requestedBookId,
    required String requestedBookTitle,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Create swap offer in Firestore with status 'pending'
      await _swapService.createSwapOffer(
        recipientId: recipientId,
        recipientEmail: recipientEmail,
        offeredBookId: offeredBookId,
        offeredBookTitle: offeredBookTitle,
        requestedBookId: requestedBookId,
        requestedBookTitle: requestedBookTitle,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to create swap offer: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Accepts a swap offer and deletes both books
  /// Called when recipient taps "Accept" on received offer
  Future<void> acceptOffer(String offerId) async {
    try {
      // This will update status to 'accepted' and delete both books
      await _swapService.acceptOffer(offerId);
    } catch (e) {
      _error = 'Failed to accept offer: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Rejects a swap offer
  /// Called when recipient taps "Reject" on received offer
  Future<void> rejectOffer(String offerId) async {
    try {
      // This will update status to 'rejected'
      await _swapService.rejectOffer(offerId);
    } catch (e) {
      _error = 'Failed to reject offer: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Cancels a pending swap offer
  /// Called when sender wants to cancel their own offer
  Future<void> cancelOffer(String offerId) async {
    try {
      // This will delete the offer document completely
      await _swapService.cancelOffer(offerId);
    } catch (e) {
      _error = 'Failed to cancel offer: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Clears any existing error state
  /// Used to reset error messages in UI
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

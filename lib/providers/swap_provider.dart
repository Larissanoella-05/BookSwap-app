import 'package:flutter/foundation.dart';
import '../models/swap_offer.dart';
import '../services/swap_service.dart';

class SwapProvider with ChangeNotifier {
  final SwapService _swapService = SwapService();

  List<SwapOffer> _sentOffers = [];
  List<SwapOffer> _receivedOffers = [];
  int _pendingOffersCount = 0;
  bool _isLoading = false;
  String? _error;

  List<SwapOffer> get sentOffers => _sentOffers;
  List<SwapOffer> get receivedOffers => _receivedOffers;
  int get pendingOffersCount => _pendingOffersCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Listening to offers in real-time
  void listenToSentOffers() {
    _swapService.getSentOffers().listen(
      (offers) {
        _sentOffers = offers;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load sent offers: $error';
        notifyListeners();
      },
    );
  }

  void listenToReceivedOffers() {
    _swapService.getReceivedOffers().listen(
      (offers) {
        _receivedOffers = offers;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load received offers: $error';
        notifyListeners();
      },
    );
  }

  void listenToPendingOffersCount() {
    _swapService.getPendingReceivedOffersCount().listen((count) {
      _pendingOffersCount = count;
      notifyListeners();
    });
  }

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

  Future<void> acceptOffer(String offerId) async {
    try {
      await _swapService.acceptOffer(offerId);
    } catch (e) {
      _error = 'Failed to accept offer: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> rejectOffer(String offerId) async {
    try {
      await _swapService.rejectOffer(offerId);
    } catch (e) {
      _error = 'Failed to reject offer: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cancelOffer(String offerId) async {
    try {
      await _swapService.cancelOffer(offerId);
    } catch (e) {
      _error = 'Failed to cancel offer: $e';
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

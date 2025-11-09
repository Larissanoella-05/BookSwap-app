import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookswap/Services/swap_service.dart';
import 'package:bookswap/Models/swap.dart';

/// Provider for SwapService instance (singleton)
final swapServiceProvider = Provider<SwapService>((ref) => SwapService());

/// StreamProvider for swaps initiated by current user
final myOffersProvider = StreamProvider.family<List<Swap>, String>((ref, userId) {
  final swapService = ref.watch(swapServiceProvider);
  return swapService.getMyOffers(userId);
});

/// StreamProvider for swaps received by current user (for their books)
final receivedOffersProvider = StreamProvider.family<List<Swap>, String>((ref, userId) {
  final swapService = ref.watch(swapServiceProvider);
  return swapService.getReceivedOffers(userId);
});

/// StreamProvider for swaps for a specific book
final swapsForBookProvider = StreamProvider.family<List<Swap>, String>((ref, bookId) {
  final swapService = ref.watch(swapServiceProvider);
  return swapService.getSwapsForBook(bookId);
});

/// FutureProvider for getting a single swap by ID
final swapByIdProvider = FutureProvider.family<Swap, String>((ref, swapId) {
  final swapService = ref.watch(swapServiceProvider);
  return swapService.getSwapById(swapId);
});


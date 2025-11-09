import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for tracking last seen swap IDs to detect new swaps
final lastSeenSwapIdsProvider = StateProvider<Set<String>>((ref) => <String>{});

/// Provider for tracking last seen message IDs per chat to detect new messages
final lastSeenMessageIdsProvider = StateProvider<Map<String, Set<String>>>((ref) => <String, Set<String>>{});

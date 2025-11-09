import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookswap/Services/profile_service.dart';

/// Provider for ProfileService instance (singleton)
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});


import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:lovepin/data/local/local_cache.dart';
import 'package:lovepin/data/supabase/auth_repository.dart';
import 'package:lovepin/data/supabase/couple_repository.dart';

/// Provides the [AuthRepository] singleton.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Provides the [CoupleRepository] singleton.
final coupleRepositoryProvider = Provider<CoupleRepository>((ref) {
  return CoupleRepository();
});

/// Streams the current Supabase [AuthState] so the router can react to
/// sign-in / sign-out events.
final authStateProvider = StreamProvider<AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.onAuthStateChange;
});

/// Whether the current user is part of an active couple.
///
/// Checked synchronously by the router redirect to decide if the user should
/// be routed to the couple-link screen.
final isCoupleLinkedProvider = StateProvider<bool>((ref) {
  final coupleId = LocalCache.instance.getCoupleId();
  return coupleId != null && coupleId.isNotEmpty;
});

/// The currently signed-in Supabase [User], or `null`.
///
/// Watches [authStateProvider] so that the value is recomputed whenever the
/// auth state changes (sign-in, sign-out, token refresh, etc.).
final currentUserProvider = Provider<User?>((ref) {
  // Subscribe to auth state changes so this provider re-evaluates.
  ref.watch(authStateProvider);
  final repo = ref.read(authRepositoryProvider);
  return repo.getCurrentUser();
});

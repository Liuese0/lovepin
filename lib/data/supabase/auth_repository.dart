import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

/// Repository that encapsulates all Supabase Auth operations.
///
/// Provides email/password sign-up and sign-in, sign-out, current-user
/// lookup, auth-state streaming, and FCM token persistence.
class AuthRepository {
  AuthRepository({SupabaseClientWrapper? client})
      : _client = client ?? SupabaseClientWrapper.instance;

  final SupabaseClientWrapper _client;

  // ---------------------------------------------------------------------------
  // Authentication
  // ---------------------------------------------------------------------------

  /// Create a new account with [email] and [password].
  ///
  /// Returns the [AuthResponse] containing the session and user data.
  /// Throws an [AuthException] on failure (e.g. duplicate email).
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      final normalizedMessage = e.message.toLowerCase();
      final isUserSaveFailure =
          normalizedMessage.contains('database error saving new user') ||
          normalizedMessage.contains('unexpected_failure');

      if (isUserSaveFailure) {
        throw AuthException(
          '회원가입 중 사용자 프로필 저장에 실패했습니다. '
          'Supabase SQL Editor에서 `supabase/full_setup.sql`을 실행해 '
          '`handle_new_user` 트리거와 `users` 테이블을 복구한 뒤 다시 시도해주세요.',
        );
      }

      rethrow;
    } catch (e) {
      throw AuthException('Sign-up failed: $e');
    }
  }

  /// Sign in an existing user with [email] and [password].
  ///
  /// Returns the [AuthResponse] containing the refreshed session.
  /// Throws an [AuthException] on invalid credentials.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Sign-in failed: $e');
    }
  }

  /// Sign the current user out and clear the local session.
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Sign-out failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // User state
  // ---------------------------------------------------------------------------

  /// Returns the currently authenticated [User], or `null` if no session
  /// is active.
  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  /// A broadcast stream that emits an [AuthState] whenever the
  /// authentication status changes (sign-in, sign-out, token refresh, etc.).
  Stream<AuthState> get onAuthStateChange {
    return _client.auth.onAuthStateChange;
  }

  // ---------------------------------------------------------------------------
  // FCM token
  // ---------------------------------------------------------------------------

  /// Persist the device's FCM push-notification [token] against the
  /// current user's row in the `users` table.
  ///
  /// Throws if no user is currently signed in.
  Future<void> updateFcmToken(String token) async {
    try {
      final user = getCurrentUser();
      if (user == null) {
        throw AuthException('Cannot update FCM token: no user signed in.');
      }

      await _client.database('users').update({
        'fcm_token': token,
      }).eq('id', user.id);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to update FCM token: $e');
    }
  }
}

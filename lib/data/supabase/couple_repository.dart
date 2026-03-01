import 'dart:math';

import 'package:uuid/uuid.dart';

import '../models/couple_model.dart';
import '../models/user_model.dart';
import 'supabase_client.dart';

/// Repository for creating, joining, querying, and unlinking couple pairings.
///
/// Relies on two Supabase tables:
/// - `couples` -- the couple record itself.
/// - `couple_members` -- join table linking users to a couple with a `role`
///   (`creator` or `joiner`).
class CoupleRepository {
  CoupleRepository({SupabaseClientWrapper? client})
      : _client = client ?? SupabaseClientWrapper.instance;

  final SupabaseClientWrapper _client;

  static const _codeLength = 6;
  static const _codeChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static const _inviteDuration = Duration(hours: 24);

  // ---------------------------------------------------------------------------
  // Invite code
  // ---------------------------------------------------------------------------

  /// Generate a random 6-character alphanumeric invite code.
  String generateInviteCode() {
    final random = Random.secure();
    return List.generate(
      _codeLength,
      (_) => _codeChars[random.nextInt(_codeChars.length)],
    ).join();
  }

  // ---------------------------------------------------------------------------
  // Create couple
  // ---------------------------------------------------------------------------

  /// Create a new couple record for the user identified by [userId].
  ///
  /// Generates a unique invite code, persists the couple row with status
  /// `pending`, and inserts a `couple_members` entry with role `creator`.
  ///
  /// Returns the newly created [CoupleModel].
  Future<CoupleModel> createCouple(String userId) async {
    try {
      const uuid = Uuid();
      final coupleId = uuid.v4();
      final inviteCode = generateInviteCode();
      final now = DateTime.now().toUtc();
      final expiresAt = now.add(_inviteDuration);

      final coupleJson = {
        'id': coupleId,
        'invite_code': inviteCode,
        'invite_expires_at': expiresAt.toIso8601String(),
        'status': CoupleStatus.pending.value,
        'linked_at': null,
        'created_at': now.toIso8601String(),
      };

      // Insert couple row.
      final data = await _client
          .database('couples')
          .insert(coupleJson)
          .select()
          .single();

      // Insert creator membership.
      await _client.database('couple_members').insert({
        'id': uuid.v4(),
        'couple_id': coupleId,
        'user_id': userId,
        'role': 'creator',
        'joined_at': now.toIso8601String(),
      });

      return CoupleModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to create couple: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Join couple
  // ---------------------------------------------------------------------------

  /// Join an existing couple using the [inviteCode].
  ///
  /// Validates that the code exists and has not expired, inserts a
  /// `couple_members` entry with role `joiner`, and updates the couple
  /// status to `active`.
  ///
  /// Returns the updated [CoupleModel].
  Future<CoupleModel> joinCouple(String inviteCode, String userId) async {
    try {
      // Look up couple by invite code.
      final coupleRows = await _client
          .database('couples')
          .select()
          .eq('invite_code', inviteCode.toUpperCase())
          .eq('status', CoupleStatus.pending.value);

      if (coupleRows.isEmpty) {
        throw Exception(
          'Invalid or already-used invite code: $inviteCode',
        );
      }

      final coupleData = coupleRows.first as Map<String, dynamic>;
      final couple = CoupleModel.fromJson(coupleData);

      if (couple.isExpired) {
        throw Exception('Invite code has expired.');
      }

      // Ensure the joiner is not the same user who created the couple.
      final existingMembers = await _client
          .database('couple_members')
          .select()
          .eq('couple_id', couple.id)
          .eq('user_id', userId);

      if (existingMembers.isNotEmpty) {
        throw Exception('You are already a member of this couple.');
      }

      final now = DateTime.now().toUtc();
      const uuid = Uuid();

      // Insert joiner membership.
      await _client.database('couple_members').insert({
        'id': uuid.v4(),
        'couple_id': couple.id,
        'user_id': userId,
        'role': 'joiner',
        'joined_at': now.toIso8601String(),
      });

      // Activate the couple.
      final updatedData = await _client
          .database('couples')
          .update({
            'status': CoupleStatus.active.value,
            'linked_at': now.toIso8601String(),
          })
          .eq('id', couple.id)
          .select()
          .single();

      return CoupleModel.fromJson(updatedData);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to join couple: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Query helpers
  // ---------------------------------------------------------------------------

  /// Retrieve the couple that [userId] belongs to, or `null` if the user
  /// is not part of any couple.
  ///
  /// Performs a join through `couple_members` to locate the related couple
  /// record.
  Future<CoupleModel?> getMyCouple(String userId) async {
    try {
      final memberRows = await _client
          .database('couple_members')
          .select('couple_id, couples(*)')
          .eq('user_id', userId);

      if (memberRows.isEmpty) return null;

      final row = memberRows.first as Map<String, dynamic>;
      final coupleData = row['couples'] as Map<String, dynamic>?;

      if (coupleData == null) return null;

      return CoupleModel.fromJson(coupleData);
    } catch (e) {
      throw Exception('Failed to get couple for user $userId: $e');
    }
  }

  /// Retrieve the partner's [UserModel] for the given [coupleId], excluding
  /// the user identified by [myUserId].
  ///
  /// Returns `null` if the couple has no other member (e.g. still pending).
  Future<UserModel?> getPartner(String coupleId, String myUserId) async {
    try {
      final memberRows = await _client
          .database('couple_members')
          .select('user_id, users(*)')
          .eq('couple_id', coupleId)
          .neq('user_id', myUserId);

      if (memberRows.isEmpty) return null;

      final row = memberRows.first as Map<String, dynamic>;
      final userData = row['users'] as Map<String, dynamic>?;

      if (userData == null) return null;

      return UserModel.fromJson(userData);
    } catch (e) {
      throw Exception('Failed to get partner for couple $coupleId: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Unlink
  // ---------------------------------------------------------------------------

  /// Mark the couple identified by [coupleId] as unlinked.
  Future<void> unlinkCouple(String coupleId) async {
    try {
      await _client
          .database('couples')
          .update({'status': CoupleStatus.unlinked.value})
          .eq('id', coupleId);
    } catch (e) {
      throw Exception('Failed to unlink couple $coupleId: $e');
    }
  }
}

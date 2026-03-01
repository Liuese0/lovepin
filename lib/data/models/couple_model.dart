/// Possible states a couple record can be in.
enum CoupleStatus {
  /// The invite has been created but the partner has not yet joined.
  pending('pending'),

  /// Both partners are linked and the couple is active.
  active('active'),

  /// One partner chose to unlink; the couple is dissolved.
  unlinked('unlinked');

  const CoupleStatus(this.value);

  /// The raw string stored in the database.
  final String value;

  /// Look up a [CoupleStatus] from its database string value.
  ///
  /// Throws [ArgumentError] if [value] does not match any variant.
  static CoupleStatus fromValue(String value) {
    return CoupleStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw ArgumentError(
        'Unknown CoupleStatus value: $value',
      ),
    );
  }
}

/// Data model representing a couple pairing in Lovepin.
///
/// Maps to the `couples` table in Supabase. A couple is created when one
/// user generates an invite code and becomes *active* when the partner joins.
class CoupleModel {
  final String id;
  final String inviteCode;
  final DateTime inviteExpiresAt;
  final CoupleStatus status;
  final DateTime? linkedAt;
  final DateTime createdAt;

  const CoupleModel({
    required this.id,
    required this.inviteCode,
    required this.inviteExpiresAt,
    required this.status,
    this.linkedAt,
    required this.createdAt,
  });

  /// Deserialise a Supabase row into a [CoupleModel].
  factory CoupleModel.fromJson(Map<String, dynamic> json) {
    return CoupleModel(
      id: json['id'] as String,
      inviteCode: json['invite_code'] as String,
      inviteExpiresAt: DateTime.parse(json['invite_expires_at'] as String),
      status: CoupleStatus.fromValue(json['status'] as String),
      linkedAt: json['linked_at'] != null
          ? DateTime.parse(json['linked_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Serialise to a JSON map suitable for Supabase insert / update.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invite_code': inviteCode,
      'invite_expires_at': inviteExpiresAt.toIso8601String(),
      'status': status.value,
      'linked_at': linkedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Returns a shallow copy with the given fields replaced.
  CoupleModel copyWith({
    String? id,
    String? inviteCode,
    DateTime? inviteExpiresAt,
    CoupleStatus? status,
    DateTime? linkedAt,
    bool clearLinkedAt = false,
    DateTime? createdAt,
  }) {
    return CoupleModel(
      id: id ?? this.id,
      inviteCode: inviteCode ?? this.inviteCode,
      inviteExpiresAt: inviteExpiresAt ?? this.inviteExpiresAt,
      status: status ?? this.status,
      linkedAt: clearLinkedAt ? null : (linkedAt ?? this.linkedAt),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Whether the invite code has passed its expiry time.
  bool get isExpired => DateTime.now().isAfter(inviteExpiresAt);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoupleModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          inviteCode == other.inviteCode &&
          inviteExpiresAt == other.inviteExpiresAt &&
          status == other.status &&
          linkedAt == other.linkedAt &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        inviteCode,
        inviteExpiresAt,
        status,
        linkedAt,
        createdAt,
      );

  @override
  String toString() {
    return 'CoupleModel(id: $id, inviteCode: $inviteCode, '
        'inviteExpiresAt: $inviteExpiresAt, status: ${status.value}, '
        'linkedAt: $linkedAt, createdAt: $createdAt)';
  }
}

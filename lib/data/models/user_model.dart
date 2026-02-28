/// Data model representing a Lovepin user profile.
///
/// Maps to the `users` table in Supabase. Each user has a display name,
/// optional avatar, optional widget theme selection, and an optional
/// FCM token for push notifications.
class UserModel {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? selectedThemeId;
  final String? fcmToken;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.selectedThemeId,
    this.fcmToken,
    required this.createdAt,
  });

  /// Deserialise a Supabase row (or any JSON map) into a [UserModel].
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      selectedThemeId: json['selected_theme_id'] as String?,
      fcmToken: json['fcm_token'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Serialise to a JSON map suitable for Supabase insert / update.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'selected_theme_id': selectedThemeId,
      'fcm_token': fcmToken,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Returns a shallow copy with the given fields replaced.
  UserModel copyWith({
    String? id,
    String? displayName,
    String? avatarUrl,
    bool clearAvatarUrl = false,
    String? selectedThemeId,
    bool clearSelectedThemeId = false,
    String? fcmToken,
    bool clearFcmToken = false,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatarUrl: clearAvatarUrl ? null : (avatarUrl ?? this.avatarUrl),
      selectedThemeId: clearSelectedThemeId
          ? null
          : (selectedThemeId ?? this.selectedThemeId),
      fcmToken: clearFcmToken ? null : (fcmToken ?? this.fcmToken),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          displayName == other.displayName &&
          avatarUrl == other.avatarUrl &&
          selectedThemeId == other.selectedThemeId &&
          fcmToken == other.fcmToken &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        displayName,
        avatarUrl,
        selectedThemeId,
        fcmToken,
        createdAt,
      );

  @override
  String toString() {
    return 'UserModel(id: $id, displayName: $displayName, '
        'avatarUrl: $avatarUrl, selectedThemeId: $selectedThemeId, '
        'fcmToken: $fcmToken, createdAt: $createdAt)';
  }
}

/// Data model representing a single message sent between partners.
///
/// Maps to the `messages` table in Supabase. Messages belong to a couple
/// and may optionally contain an image and/or reference a template.
class MessageModel {
  final String id;
  final String coupleId;
  final String senderId;
  final String content;
  final String? imageUrl;
  final String? imageThumbnailUrl;
  final String? templateId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.coupleId,
    required this.senderId,
    required this.content,
    this.imageUrl,
    this.imageThumbnailUrl,
    this.templateId,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
  });

  /// Deserialise a Supabase row into a [MessageModel].
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      coupleId: json['couple_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      imageUrl: json['image_url'] as String?,
      imageThumbnailUrl: json['image_thumbnail_url'] as String?,
      templateId: json['template_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Serialise to a JSON map suitable for Supabase insert / update.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'couple_id': coupleId,
      'sender_id': senderId,
      'content': content,
      'image_url': imageUrl,
      'image_thumbnail_url': imageThumbnailUrl,
      'template_id': templateId,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Returns a shallow copy with the given fields replaced.
  MessageModel copyWith({
    String? id,
    String? coupleId,
    String? senderId,
    String? content,
    String? imageUrl,
    bool clearImageUrl = false,
    String? imageThumbnailUrl,
    bool clearImageThumbnailUrl = false,
    String? templateId,
    bool clearTemplateId = false,
    bool? isRead,
    DateTime? readAt,
    bool clearReadAt = false,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      coupleId: coupleId ?? this.coupleId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      imageThumbnailUrl: clearImageThumbnailUrl
          ? null
          : (imageThumbnailUrl ?? this.imageThumbnailUrl),
      templateId: clearTemplateId ? null : (templateId ?? this.templateId),
      isRead: isRead ?? this.isRead,
      readAt: clearReadAt ? null : (readAt ?? this.readAt),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          coupleId == other.coupleId &&
          senderId == other.senderId &&
          content == other.content &&
          imageUrl == other.imageUrl &&
          imageThumbnailUrl == other.imageThumbnailUrl &&
          templateId == other.templateId &&
          isRead == other.isRead &&
          readAt == other.readAt &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        coupleId,
        senderId,
        content,
        imageUrl,
        imageThumbnailUrl,
        templateId,
        isRead,
        readAt,
        createdAt,
      );

  @override
  String toString() {
    return 'MessageModel(id: $id, coupleId: $coupleId, '
        'senderId: $senderId, content: $content, '
        'imageUrl: $imageUrl, templateId: $templateId, '
        'isRead: $isRead, createdAt: $createdAt)';
  }
}

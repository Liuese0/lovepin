import 'dart:io';

import 'package:uuid/uuid.dart';

import '../models/message_model.dart';
import 'supabase_client.dart';

/// Repository for sending, querying, and managing messages between partners.
///
/// Messages live in the `messages` Supabase table. Image attachments are
/// uploaded to the `message_images` Supabase Storage bucket.
class MessageRepository {
  MessageRepository({SupabaseClientWrapper? client})
      : _client = client ?? SupabaseClientWrapper.instance;

  final SupabaseClientWrapper _client;

  static const _storageBucket = 'message_images';
  static const _thumbnailBucket = 'message_thumbnails';

  // ---------------------------------------------------------------------------
  // Send
  // ---------------------------------------------------------------------------

  /// Insert a new message into the `messages` table.
  ///
  /// Returns the persisted [MessageModel] (including server-generated
  /// defaults such as `created_at` if the column has a DB default).
  Future<MessageModel> sendMessage({
    required String coupleId,
    required String senderId,
    required String content,
    String? imageUrl,
    String? imageThumbnailUrl,
    String? templateId,
  }) async {
    try {
      const uuid = Uuid();
      final now = DateTime.now().toUtc();

      final messageJson = {
        'id': uuid.v4(),
        'couple_id': coupleId,
        'sender_id': senderId,
        'content': content,
        'image_url': imageUrl,
        'image_thumbnail_url': imageThumbnailUrl,
        'template_id': templateId,
        'is_read': false,
        'read_at': null,
        'created_at': now.toIso8601String(),
      };

      final data = await _client
          .database('messages')
          .insert(messageJson)
          .select()
          .single();

      return MessageModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Query
  // ---------------------------------------------------------------------------

  /// Retrieve a paginated list of messages for the given [coupleId],
  /// ordered newest-first.
  Future<List<MessageModel>> getMessages(
    String coupleId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final data = await _client
          .database('messages')
          .select()
          .eq('couple_id', coupleId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (data as List<dynamic>)
          .map((row) => MessageModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get messages for couple $coupleId: $e');
    }
  }

  /// Retrieve the single most recent message for [coupleId], or `null` if
  /// the couple has no messages yet.
  Future<MessageModel?> getLatestMessage(String coupleId) async {
    try {
      final data = await _client
          .database('messages')
          .select()
          .eq('couple_id', coupleId)
          .order('created_at', ascending: false)
          .limit(1);

      if ((data as List<dynamic>).isEmpty) return null;

      return MessageModel.fromJson(data.first as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get latest message for couple $coupleId: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Read receipts
  // ---------------------------------------------------------------------------

  /// Mark all unread messages in [coupleId] that were **not** sent by
  /// [receiverId] as read.
  ///
  /// This is a bulk update: every message where `is_read = false` and
  /// `sender_id != receiverId` is updated in a single query.
  Future<void> markAsRead(String coupleId, String receiverId) async {
    try {
      final now = DateTime.now().toUtc();

      await _client
          .database('messages')
          .update({
            'is_read': true,
            'read_at': now.toIso8601String(),
          })
          .eq('couple_id', coupleId)
          .neq('sender_id', receiverId)
          .eq('is_read', false);
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Image upload
  // ---------------------------------------------------------------------------

  /// Upload a full-size image [file] to the `message_images` storage bucket
  /// scoped under [coupleId].
  ///
  /// Returns the public URL of the uploaded file.
  Future<String> uploadImage(File file, String coupleId) async {
    try {
      const uuid = Uuid();
      final extension = file.path.split('.').last;
      final filePath = '$coupleId/${uuid.v4()}.$extension';

      await _client.storage.from(_storageBucket).upload(
            filePath,
            file,
          );

      final publicUrl =
          _client.storage.from(_storageBucket).getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload a thumbnail image [file] to the `message_thumbnails` storage
  /// bucket scoped under [coupleId].
  ///
  /// Returns the public URL of the uploaded thumbnail.
  Future<String> uploadThumbnail(File file, String coupleId) async {
    try {
      const uuid = Uuid();
      final extension = file.path.split('.').last;
      final filePath = '$coupleId/${uuid.v4()}_thumb.$extension';

      await _client.storage.from(_thumbnailBucket).upload(
            filePath,
            file,
          );

      final publicUrl =
          _client.storage.from(_thumbnailBucket).getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload thumbnail: $e');
    }
  }
}

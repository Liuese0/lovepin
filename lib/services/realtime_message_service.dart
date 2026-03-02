import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/message_model.dart';
import 'widget_service.dart';

/// Manages a Supabase Realtime subscription on the `messages` table and
/// automatically updates the home-screen widget when a new message arrives
/// from the partner.
///
/// Usage:
/// ```dart
/// RealtimeMessageService.instance.start(
///   coupleId: 'abc',
///   currentUserId: 'user1',
///   partnerName: 'Jane',
/// );
/// ```
class RealtimeMessageService {
  RealtimeMessageService._();

  static final RealtimeMessageService _instance =
      RealtimeMessageService._();

  static RealtimeMessageService get instance => _instance;

  RealtimeChannel? _channel;
  String? _currentCoupleId;

  /// Start listening for new messages for the given [coupleId].
  ///
  /// When a message arrives whose sender differs from [currentUserId],
  /// the home-screen widget is updated automatically.
  void start({
    required String coupleId,
    required String currentUserId,
    required String partnerName,
  }) {
    // Avoid duplicate subscriptions for the same couple.
    if (_channel != null && _currentCoupleId == coupleId) return;

    // Clean up any existing subscription first.
    stop();

    _currentCoupleId = coupleId;

    final client = Supabase.instance.client;

    _channel = client
        .channel('widget-messages-$coupleId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'couple_id',
            value: coupleId,
          ),
          callback: (PostgresChangePayload payload) {
            _handleNewMessage(payload, currentUserId, partnerName);
          },
        )
        .subscribe();

    debugPrint('[RealtimeMessageService] Subscribed for couple: $coupleId');
  }

  /// Stop listening and remove the channel.
  void stop() {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
      _channel = null;
      _currentCoupleId = null;
      debugPrint('[RealtimeMessageService] Unsubscribed.');
    }
  }

  void _handleNewMessage(
    PostgresChangePayload payload,
    String currentUserId,
    String partnerName,
  ) {
    try {
      final newRecord = payload.newRecord;
      final message = MessageModel.fromJson(newRecord);

      // Only update widget for partner's messages, not our own.
      if (message.senderId != currentUserId) {
        WidgetService.updateWidget(
          message,
          senderName: partnerName,
          userId: currentUserId,
        );
        debugPrint(
            '[RealtimeMessageService] Widget updated with partner message.');
      }
    } catch (e) {
      debugPrint('[RealtimeMessageService] Failed to handle message: $e');
    }
  }
}

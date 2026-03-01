import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/message_model.dart';

/// Hive-backed local cache for offline-first data access.
///
/// Stores the latest message, couple metadata, and a list of cached messages
/// so the home-screen widget and app UI can display content instantly while
/// waiting for network responses.
///
/// Call [init] once at app startup (after `Hive.initFlutter()`).
class LocalCache {
  LocalCache._();

  static final LocalCache _instance = LocalCache._();

  /// The singleton instance of [LocalCache].
  static LocalCache get instance => _instance;

  static const _boxName = 'lovepin_cache';

  // Hive keys
  static const _keyLatestMessage = 'latest_message';
  static const _keyCoupleId = 'couple_id';
  static const _keyPartnerId = 'partner_id';
  static const _keySelectedThemeId = 'selected_theme_id';
  static const _keyCachedMessages = 'cached_messages';
  static const _keyRememberMe = 'remember_me';

  late Box<dynamic> _box;

  /// Initialise the Hive box. Must be called once after
  /// `Hive.initFlutter()` and before any read / write operations.
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  // ---------------------------------------------------------------------------
  // Latest message
  // ---------------------------------------------------------------------------

  /// Persist the most recent [MessageModel] as a JSON string.
  Future<void> saveLatestMessage(MessageModel message) async {
    final jsonString = jsonEncode(message.toJson());
    await _box.put(_keyLatestMessage, jsonString);
  }

  /// Retrieve the cached latest message, or `null` if nothing is stored.
  MessageModel? getLatestMessage() {
    final jsonString = _box.get(_keyLatestMessage) as String?;
    if (jsonString == null) return null;

    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return MessageModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Couple info
  // ---------------------------------------------------------------------------

  /// Cache the [coupleId] and [partnerId] for quick offline access.
  Future<void> saveCoupleInfo({
    required String coupleId,
    required String partnerId,
  }) async {
    await _box.put(_keyCoupleId, coupleId);
    await _box.put(_keyPartnerId, partnerId);
  }

  /// Retrieve the cached couple ID, or `null`.
  String? getCoupleId() {
    return _box.get(_keyCoupleId) as String?;
  }

  /// Retrieve the cached partner ID, or `null`.
  String? getPartnerId() {
    return _box.get(_keyPartnerId) as String?;
  }

  // ---------------------------------------------------------------------------
  // Selected theme
  // ---------------------------------------------------------------------------

  /// Persist the currently selected widget theme ID.
  Future<void> saveSelectedThemeId(String themeId) async {
    await _box.put(_keySelectedThemeId, themeId);
  }

  /// Retrieve the cached selected theme ID, or `null`.
  String? getSelectedThemeId() {
    return _box.get(_keySelectedThemeId) as String?;
  }

  // ---------------------------------------------------------------------------
  // Cached messages list
  // ---------------------------------------------------------------------------

  /// Persist a list of [MessageModel]s as a JSON-encoded string list.
  Future<void> saveMessages(List<MessageModel> messages) async {
    final jsonList = messages.map((m) => jsonEncode(m.toJson())).toList();
    await _box.put(_keyCachedMessages, jsonList);
  }

  /// Retrieve the cached list of messages, or an empty list.
  List<MessageModel> getMessages() {
    final raw = _box.get(_keyCachedMessages);
    if (raw == null) return [];

    try {
      final jsonList = (raw as List<dynamic>).cast<String>();
      return jsonList.map((jsonString) {
        final map = jsonDecode(jsonString) as Map<String, dynamic>;
        return MessageModel.fromJson(map);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Remember me
  // ---------------------------------------------------------------------------

  /// Persist the "remember me" preference.
  Future<void> saveRememberMe(bool value) async {
    await _box.put(_keyRememberMe, value);
  }

  /// Whether the user chose to be remembered. Defaults to `false`.
  bool getRememberMe() {
    return _box.get(_keyRememberMe, defaultValue: false) as bool;
  }

  // ---------------------------------------------------------------------------
  // Clear
  // ---------------------------------------------------------------------------

  /// Remove all cached data. Typically called on sign-out or couple unlink.
  Future<void> clear() async {
    await _box.clear();
  }
}
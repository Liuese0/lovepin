import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:path_provider/path_provider.dart';

import '../data/models/message_model.dart';
import '../data/models/theme_model.dart';

/// Manages home screen widget updates on both iOS and Android.
///
/// Uses the `home_widget` package to persist message data into platform-native
/// storage (iOS App Group / Android SharedPreferences) and triggers a widget
/// redraw so the latest love note appears on the partner's home screen.
class WidgetService {
  WidgetService._();

  // ---------------------------------------------------------------------------
  // Constants
  // ---------------------------------------------------------------------------

  /// The iOS widget kind identifier registered in the WidgetKit extension.
  static const String _iOSWidgetName = 'LovepinWidget';

  /// The fully-qualified Android AppWidgetProvider class name.
  static const String _androidWidgetName = 'LovepinWidgetProvider';

  /// The App Group identifier shared between the Flutter app and the iOS
  /// widget extension.
  static const String _appGroupId = 'group.com.lovepin.shared';

  // SharedPreferences / UserDefaults keys used by native widget code.
  static const String _keyMessageContent = 'message_content';
  static const String _keySenderName = 'sender_name';
  static const String _keyImagePath = 'image_path';
  static const String _keyTimestamp = 'message_timestamp';
  static const String _keyBackgroundColor = 'theme_background_color';
  static const String _keyTextColor = 'theme_text_color';
  static const String _keyAccentColor = 'theme_accent_color';
  static const String _keyUserId = 'widget_user_id';

  // ---------------------------------------------------------------------------
  // Default theme colours (Rose Petal)
  // ---------------------------------------------------------------------------

  static const String _defaultBackgroundColor = '#FFD6E0';
  static const String _defaultTextColor = '#2D2D2D';
  static const String _defaultAccentColor = '#FF8FAB';

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  /// Initialise the widget service.
  ///
  /// Must be called once during app startup (typically in `main()`).
  /// Registers the App Group for iOS and sets up the background callback
  /// that handles interactive widget actions.
  static Future<void> initializeWidget() async {
    try {
      // Set the App Group so the home_widget plugin writes to the correct
      // shared container on iOS.
      await HomeWidget.setAppGroupId(_appGroupId);

      // Register the static background callback for interactive widget taps
      // or background updates triggered by the system.
      await HomeWidget.registerInteractivityCallback(backgroundCallback);

      debugPrint('[WidgetService] Widget initialised successfully.');
    } catch (e, stack) {
      debugPrint('[WidgetService] Initialisation failed: $e');
      debugPrint('$stack');
    }
  }

  // ---------------------------------------------------------------------------
  // Widget update
  // ---------------------------------------------------------------------------

  /// Persist the latest [message] into platform-native storage and trigger a
  /// widget redraw on the home screen.
  ///
  /// If a [theme] is provided its colours are saved alongside the message data
  /// so the native widget can render the correct pastel background and text
  /// colours. When [theme] is `null` the default Rose Petal palette is used.
  static Future<void> updateWidget(
    MessageModel message, {
    WidgetThemeModel? theme,
    String? senderName,
    String? userId,
  }) async {
    try {
      // -----------------------------------------------------------------------
      // 1. Download image locally (if present) so the native widget can
      //    render it as a Bitmap without network access.
      // -----------------------------------------------------------------------
      final imageUrl = message.imageThumbnailUrl ?? message.imageUrl;
      String localImagePath = '';
      if (imageUrl != null && imageUrl.isNotEmpty) {
        localImagePath = await _downloadWidgetImage(imageUrl) ?? '';
      }

      // -----------------------------------------------------------------------
      // 2. Save message data + owner
      // -----------------------------------------------------------------------
      await Future.wait([
        HomeWidget.saveWidgetData<String>(
          _keyMessageContent,
          message.content,
        ),
        HomeWidget.saveWidgetData<String>(
          _keySenderName,
          senderName ?? 'Your Love',
        ),
        HomeWidget.saveWidgetData<String>(
          _keyImagePath,
          localImagePath,
        ),
        HomeWidget.saveWidgetData<String>(
          _keyTimestamp,
          message.createdAt.toIso8601String(),
        ),
        if (userId != null)
          HomeWidget.saveWidgetData<String>(_keyUserId, userId),
      ]);

      // -----------------------------------------------------------------------
      // 2. Save theme colours
      // -----------------------------------------------------------------------
      final String bgColor = theme?.backgroundColor ?? _defaultBackgroundColor;
      final String txtColor = theme?.textColor ?? _defaultTextColor;
      final String accColor = theme?.accentColor ?? _defaultAccentColor;

      await Future.wait([
        HomeWidget.saveWidgetData<String>(_keyBackgroundColor, bgColor),
        HomeWidget.saveWidgetData<String>(_keyTextColor, txtColor),
        HomeWidget.saveWidgetData<String>(_keyAccentColor, accColor),
      ]);

      // -----------------------------------------------------------------------
      // 3. Trigger native widget update
      // -----------------------------------------------------------------------
      await HomeWidget.updateWidget(
        iOSName: _iOSWidgetName,
        androidName: _androidWidgetName,
      );

      debugPrint('[WidgetService] Widget updated with message: '
          '${message.id}');
    } catch (e, stack) {
      debugPrint('[WidgetService] Failed to update widget: $e');
      debugPrint('$stack');
    }
  }

  /// Clear all widget data and reset to an empty state.
  ///
  /// Called when the user logs out or unlinks from their partner so stale
  /// messages are not displayed on the home screen.
  static Future<void> clearWidget() async {
    try {
      await Future.wait([
        HomeWidget.saveWidgetData<String>(_keyMessageContent, ''),
        HomeWidget.saveWidgetData<String>(_keySenderName, ''),
        HomeWidget.saveWidgetData<String>(_keyImagePath, ''),
        HomeWidget.saveWidgetData<String>(_keyTimestamp, ''),
        HomeWidget.saveWidgetData<String>(_keyUserId, ''),
        HomeWidget.saveWidgetData<String>(
          _keyBackgroundColor,
          _defaultBackgroundColor,
        ),
        HomeWidget.saveWidgetData<String>(
          _keyTextColor,
          _defaultTextColor,
        ),
        HomeWidget.saveWidgetData<String>(
          _keyAccentColor,
          _defaultAccentColor,
        ),
      ]);

      await HomeWidget.updateWidget(
        iOSName: _iOSWidgetName,
        androidName: _androidWidgetName,
      );

      debugPrint('[WidgetService] Widget cleared.');
    } catch (e, stack) {
      debugPrint('[WidgetService] Failed to clear widget: $e');
      debugPrint('$stack');
    }
  }

  // ---------------------------------------------------------------------------
  // Background callback
  // ---------------------------------------------------------------------------

  /// Static callback registered with `home_widget` to handle interactive
  /// widget events that arrive while the app is in the background or killed.
  ///
  /// The [uri] encodes the action the user triggered — for Lovepin the only
  /// action is a tap-to-open deep link, but the callback is required by
  /// `home_widget` even if unused.
  @pragma('vm:entry-point')
  static Future<void> backgroundCallback(Uri? uri) async {
    if (uri == null) return;

    debugPrint('[WidgetService] Background callback received: $uri');

    // The host part of the URI indicates the action.
    // For now we only handle `open_app` but this is extensible.
    switch (uri.host) {
      case 'open_app':
        // The app will be brought to the foreground automatically by the
        // system when the user taps the widget. No extra work needed here.
        break;

      case 'refresh':
        // A future enhancement could re-fetch the latest message from
        // Supabase and update the widget data from the background.
        break;

      default:
        debugPrint('[WidgetService] Unknown background action: ${uri.host}');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Download an image from [url] and save it as `widget_image.jpg` in the
  /// app's documents directory (internal storage, always accessible by the
  /// widget provider).  Returns the absolute file path on success, or `null`
  /// on failure.
  static Future<String?> _downloadWidgetImage(String url) async {
    try {
      debugPrint('[WidgetService] Downloading widget image: $url');

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/widget_image.jpg');

      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      debugPrint('[WidgetService] Image response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final bytes = await consolidateHttpClientResponseBytes(response);
        await file.writeAsBytes(bytes);
        client.close();
        debugPrint('[WidgetService] Image saved to: ${file.path} '
            '(${bytes.length} bytes)');
        return file.path;
      }

      // Follow redirects (3xx)
      if (response.statusCode >= 300 && response.statusCode < 400) {
        final location = response.headers.value('location');
        client.close();
        if (location != null) {
          debugPrint('[WidgetService] Following redirect: $location');
          return _downloadWidgetImage(location);
        }
      }

      client.close();
      debugPrint('[WidgetService] Image download failed: HTTP ${response.statusCode}');
    } catch (e) {
      debugPrint('[WidgetService] Image download failed: $e');
    }
    return null;
  }

  /// Clear the widget if the stored owner does not match [currentUserId].
  ///
  /// Prevents stale data from a different account being displayed when the
  /// user switches accounts on the same device.
  static Future<void> clearIfOwnerChanged(String currentUserId) async {
    try {
      final storedUserId = await HomeWidget.getWidgetData<String>(_keyUserId);
      if (storedUserId != null &&
          storedUserId.isNotEmpty &&
          storedUserId != currentUserId) {
        debugPrint('[WidgetService] Owner changed, clearing widget.');
        await clearWidget();
      }
    } catch (e) {
      debugPrint('[WidgetService] Failed to validate owner: $e');
    }
  }

  /// Returns `true` when the widget data keys contain a non-empty message.
  ///
  /// Useful for determining whether to show a "set up your widget" prompt.
  static Future<bool> hasWidgetData() async {
    try {
      final content = await HomeWidget.getWidgetData<String>(
        _keyMessageContent,
      );
      return content != null && content.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

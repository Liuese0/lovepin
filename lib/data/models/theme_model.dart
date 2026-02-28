import 'dart:ui' show Color;

/// Data model representing a visual theme for the home-screen widget.
///
/// Maps to the `widget_themes` table in Supabase. Colours are stored as
/// hex strings (e.g. `#FF5A9E`) and converted to Flutter [Color] objects
/// via the [toColor] helper.
class WidgetThemeModel {
  final String id;
  final String name;
  final String backgroundColor;
  final String textColor;
  final String accentColor;
  final String fontFamily;
  final bool isPremium;
  final String? previewUrl;

  const WidgetThemeModel({
    required this.id,
    required this.name,
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
    required this.fontFamily,
    required this.isPremium,
    this.previewUrl,
  });

  /// Deserialise a Supabase row into a [WidgetThemeModel].
  factory WidgetThemeModel.fromJson(Map<String, dynamic> json) {
    return WidgetThemeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      backgroundColor: json['background_color'] as String,
      textColor: json['text_color'] as String,
      accentColor: json['accent_color'] as String,
      fontFamily: json['font_family'] as String,
      isPremium: json['is_premium'] as bool? ?? false,
      previewUrl: json['preview_url'] as String?,
    );
  }

  /// Serialise to a JSON map suitable for Supabase insert / update.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'background_color': backgroundColor,
      'text_color': textColor,
      'accent_color': accentColor,
      'font_family': fontFamily,
      'is_premium': isPremium,
      'preview_url': previewUrl,
    };
  }

  // ---------------------------------------------------------------------------
  // Colour helpers
  // ---------------------------------------------------------------------------

  /// Parse a hex colour string into a Flutter [Color].
  ///
  /// Accepts formats: `#RGB`, `#RRGGBB`, `#AARRGGBB` (with or without `#`).
  static Color toColor(String hex) {
    String sanitised = hex.replaceAll('#', '').trim();

    // Expand shorthand #RGB to #RRGGBB.
    if (sanitised.length == 3) {
      sanitised = sanitised.split('').map((c) => '$c$c').join();
    }

    // Default to fully opaque when alpha is not specified.
    if (sanitised.length == 6) {
      sanitised = 'FF$sanitised';
    }

    final int? colorValue = int.tryParse(sanitised, radix: 16);
    if (colorValue == null) {
      return const Color(0xFF000000); // fallback to black
    }

    return Color(colorValue);
  }

  /// Convenience getter for [backgroundColor] as a Flutter [Color].
  Color get backgroundColorValue => toColor(backgroundColor);

  /// Convenience getter for [textColor] as a Flutter [Color].
  Color get textColorValue => toColor(textColor);

  /// Convenience getter for [accentColor] as a Flutter [Color].
  Color get accentColorValue => toColor(accentColor);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WidgetThemeModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          backgroundColor == other.backgroundColor &&
          textColor == other.textColor &&
          accentColor == other.accentColor &&
          fontFamily == other.fontFamily &&
          isPremium == other.isPremium &&
          previewUrl == other.previewUrl;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        backgroundColor,
        textColor,
        accentColor,
        fontFamily,
        isPremium,
        previewUrl,
      );

  @override
  String toString() {
    return 'WidgetThemeModel(id: $id, name: $name, '
        'backgroundColor: $backgroundColor, textColor: $textColor, '
        'accentColor: $accentColor, fontFamily: $fontFamily, '
        'isPremium: $isPremium, previewUrl: $previewUrl)';
  }
}

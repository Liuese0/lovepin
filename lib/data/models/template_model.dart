/// Categories a message template can belong to.
///
/// Each variant carries a human-readable display label used in the UI.
enum TemplateCategory {
  missYou('miss_you', 'Miss You'),
  cheerUp('cheer_up', 'Cheer Up'),
  sorry('sorry', 'Sorry'),
  thankYou('thank_you', 'Thank You'),
  goodMorning('good_morning', 'Good Morning'),
  goodNight('good_night', 'Good Night');

  const TemplateCategory(this.value, this.displayLabel);

  /// The raw string stored in the database column.
  final String value;

  /// A user-facing label suitable for UI display.
  final String displayLabel;

  /// Look up a [TemplateCategory] from its database string value.
  ///
  /// Throws [ArgumentError] if [value] does not match any variant.
  static TemplateCategory fromValue(String value) {
    return TemplateCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => throw ArgumentError(
        'Unknown TemplateCategory value: $value',
      ),
    );
  }
}

/// Data model representing a pre-written message template.
///
/// Maps to the `templates` table in Supabase. Templates are organised by
/// category, sorted by [sortOrder], and optionally gated behind a premium
/// flag.
class TemplateModel {
  final String id;
  final TemplateCategory category;
  final String content;
  final String language;
  final bool isPremium;
  final int sortOrder;

  const TemplateModel({
    required this.id,
    required this.category,
    required this.content,
    required this.language,
    required this.isPremium,
    required this.sortOrder,
  });

  /// Deserialise a Supabase row into a [TemplateModel].
  factory TemplateModel.fromJson(Map<String, dynamic> json) {
    return TemplateModel(
      id: json['id'] as String,
      category: TemplateCategory.fromValue(json['category'] as String),
      content: json['content'] as String,
      language: json['language'] as String,
      isPremium: json['is_premium'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  /// Serialise to a JSON map suitable for Supabase insert / update.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category.value,
      'content': content,
      'language': language,
      'is_premium': isPremium,
      'sort_order': sortOrder,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          category == other.category &&
          content == other.content &&
          language == other.language &&
          isPremium == other.isPremium &&
          sortOrder == other.sortOrder;

  @override
  int get hashCode => Object.hash(
        id,
        category,
        content,
        language,
        isPremium,
        sortOrder,
      );

  @override
  String toString() {
    return 'TemplateModel(id: $id, category: ${category.value}, '
        'content: $content, language: $language, '
        'isPremium: $isPremium, sortOrder: $sortOrder)';
  }
}

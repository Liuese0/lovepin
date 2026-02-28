import '../models/template_model.dart';
import 'supabase_client.dart';

/// Repository for querying pre-written message templates.
///
/// Templates are read-only for the client; they are managed via the
/// Supabase dashboard or admin tooling.
class TemplateRepository {
  TemplateRepository({SupabaseClientWrapper? client})
      : _client = client ?? SupabaseClientWrapper.instance;

  final SupabaseClientWrapper _client;

  // ---------------------------------------------------------------------------
  // Query
  // ---------------------------------------------------------------------------

  /// Retrieve templates, optionally filtered by [category] and/or
  /// [isPremium] status.
  ///
  /// Results are sorted by [sortOrder] ascending.
  Future<List<TemplateModel>> getTemplates({
    TemplateCategory? category,
    bool? isPremium,
  }) async {
    try {
      var query = _client.database('templates').select();

      if (category != null) {
        query = query.eq('category', category.value);
      }

      if (isPremium != null) {
        query = query.eq('is_premium', isPremium);
      }

      final data = await query.order('sort_order', ascending: true);

      return (data as List<dynamic>)
          .map((row) => TemplateModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get templates: $e');
    }
  }

  /// Convenience method that retrieves all templates for a specific
  /// [category], sorted by [sortOrder].
  Future<List<TemplateModel>> getTemplatesByCategory(
    TemplateCategory category,
  ) async {
    return getTemplates(category: category);
  }
}

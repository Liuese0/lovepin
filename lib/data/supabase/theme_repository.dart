import '../models/theme_model.dart';
import 'supabase_client.dart';

/// Repository for querying widget themes.
///
/// Themes are read-only for the client; they are managed via the Supabase
/// dashboard or admin tooling.
class ThemeRepository {
  ThemeRepository({SupabaseClientWrapper? client})
      : _client = client ?? SupabaseClientWrapper.instance;

  final SupabaseClientWrapper _client;

  // ---------------------------------------------------------------------------
  // Query
  // ---------------------------------------------------------------------------

  /// Retrieve all widget themes, optionally filtered by [isPremium] status.
  ///
  /// Results are sorted by name ascending.
  Future<List<WidgetThemeModel>> getThemes({bool? isPremium}) async {
    try {
      var query = _client.database('widget_themes').select();

      if (isPremium != null) {
        query = query.eq('is_premium', isPremium);
      }

      final data = await query.order('name', ascending: true);

      return (data as List<dynamic>)
          .map(
            (row) => WidgetThemeModel.fromJson(row as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get themes: $e');
    }
  }

  /// Retrieve a single widget theme by [id], or `null` if it does not exist.
  Future<WidgetThemeModel?> getTheme(String id) async {
    try {
      final data = await _client
          .database('widget_themes')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (data == null) return null;

      return WidgetThemeModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get theme $id: $e');
    }
  }
}

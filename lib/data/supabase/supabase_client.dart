import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton convenience wrapper around the Supabase client.
///
/// Usage:
/// ```dart
/// final db = SupabaseClientWrapper.instance;
/// final rows = await db.database.from('messages').select();
/// ```
///
/// [Supabase.initialize] must be called before accessing any getter
/// (typically in `main()` before `runApp`).
class SupabaseClientWrapper {
  SupabaseClientWrapper._();

  static final SupabaseClientWrapper _instance = SupabaseClientWrapper._();

  /// The singleton instance of [SupabaseClientWrapper].
  static SupabaseClientWrapper get instance => _instance;

  /// The raw [SupabaseClient] provided by the `supabase_flutter` package.
  SupabaseClient get client => Supabase.instance.client;

  /// Shortcut to the Supabase Auth module.
  GoTrueClient get auth => client.auth;

  /// Shortcut to query the Supabase Postgres database.
  ///
  /// Example:
  /// ```dart
  /// final data = await database.from('users').select().eq('id', userId);
  /// ```
  SupabaseQueryBuilder Function(String table) get database => client.from;

  /// Shortcut to Supabase Storage for file uploads / downloads.
  SupabaseStorageClient get storage => client.storage;

  /// Shortcut to Supabase Realtime for channel subscriptions.
  RealtimeClient get realtime => client.realtime;

  /// Shortcut to invoke Supabase Edge Functions.
  FunctionsClient get functions => client.functions;
}

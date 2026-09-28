import 'app_env.dart';

/// Configuration and credentials for Supabase Backend integration in Transit AI
class SupabaseConfig {
  /// Supabase Project URL loaded dynamically from environment
  static String get supabaseUrl => AppEnv.get(
        'SUPABASE_URL',
        fallback: 'https://your-project-id.supabase.co',
      );

  /// Supabase Anonymous / Public API Key loaded dynamically from environment
  static String get supabaseAnonKey => AppEnv.get(
        'SUPABASE_ANON_KEY',
        fallback: 'your_supabase_anon_public_key_here',
      );

  /// Check if Supabase has valid non-placeholder configuration
  static bool get isConfigured =>
      supabaseUrl.trim().isNotEmpty &&
      supabaseAnonKey.trim().isNotEmpty &&
      !supabaseUrl.contains('your-project-id') &&
      !supabaseUrl.contains('YOUR_') &&
      !supabaseAnonKey.contains('your_supabase_anon') &&
      !supabaseAnonKey.contains('YOUR_');

  /// Quick helper info for the developer / user
  static String get info => '''
Transit AI Supabase Configuration:
- URL: $supabaseUrl
- Key: $supabaseAnonKey (Publishable anon key)
- Loaded via: AppEnv (.env or --dart-define-from-file)
''';
}

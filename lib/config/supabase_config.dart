/// Configuration and credentials for Supabase Backend integration in Transit AI
///
/// WHERE KEYS ARE STORED:
/// File Path: `lib/config/supabase_config.dart`
///
/// You can update or replace the project URL and Anon Key here anytime.
class SupabaseConfig {
  /// Supabase Project URL provided by the user
  static const String supabaseUrl = 'https://your-project-id.supabase.co';

  /// Supabase Anonymous / Public API Key provided by the user
  static const String supabaseAnonKey =
      'your_supabase_anon_public_key_here';

  /// Check if Supabase has valid non-placeholder configuration
  static bool get isConfigured =>
      supabaseUrl.trim().isNotEmpty &&
      supabaseAnonKey.trim().isNotEmpty &&
      !supabaseUrl.contains('YOUR_') &&
      !supabaseAnonKey.contains('YOUR_');

  /// Quick helper info for the developer / user
  static const String info = '''
Transit AI Supabase Configuration:
- URL: $supabaseUrl
- Key: $supabaseAnonKey (Publishable anon key)
- Stored at: lib/config/supabase_config.dart
''';
}

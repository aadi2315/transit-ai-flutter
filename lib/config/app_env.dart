import 'app_env_stub.dart'
    if (dart.library.io) 'app_env_io.dart'
    if (dart.library.js_interop) 'app_env_web.dart'
    if (dart.library.html) 'app_env_web.dart';

/// Centralized environment configuration helper for PRAVHA Transit AI.
///
/// Sources prioritized:
/// 1. `--dart-define-from-file=.env` or `--dart-define=KEY=VAL`
/// 2. Local `.env` file (parsed automatically in tests, CLI, and desktop/mobile environments)
/// 3. Fallback defaults (prevents runtime crashes when .env is absent)
class AppEnv {
  /// Get environment variable by key
  static String get(String key, {String fallback = ''}) {
    return getEnvValue(key, fallback: fallback);
  }

  /// Check if an environment variable is configured with a valid non-placeholder value
  static bool has(String key) {
    final val = get(key);
    return val.isNotEmpty &&
        !val.contains('YOUR_') &&
        !val.contains('your_') &&
        val.length > 5;
  }
}

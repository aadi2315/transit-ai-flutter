import 'package:flutter/services.dart';
import 'app_env_stub.dart'
    if (dart.library.io) 'app_env_io.dart'
    if (dart.library.js_interop) 'app_env_web.dart'
    if (dart.library.html) 'app_env_web.dart';

/// Centralized environment configuration helper for PRAVHA Transit AI.
///
/// Sources prioritized:
/// 1. `--dart-define-from-file=.env` or `--dart-define=KEY=VAL`
/// 2. Asynchronously loaded `.env` from Flutter rootBundle (packaged asset in APK / iOS / Web)
/// 3. Locally loaded `.env` file via dart:io (tests, desktop)
/// 4. Embedded project defaults (guarantees APK never fails even without build flags)
class AppEnv {
  static final Map<String, String> _runtimeEnv = {};

  /// Embedded default credentials matching project configuration.
  /// Guarantees that Android APK and release builds always have working keys
  /// even if .env is missing or unbundled.
  static const Map<String, String> defaultEnv = {
    'GOOGLE_MAPS_API_KEY': 'AIzaSyDjRpb6IFTB14FxzcTyAloPkDzbfI6On-8',
    'SUPABASE_URL': 'https://wntlcbyguyrbvzgihugi.supabase.co',
    'SUPABASE_ANON_KEY': 'sb_publishable_FC03eAb0E2Zp4l9MQoiu3g_v57SqqPP',
    'GEMINI_API_KEY': 'AQ.Ab8RN6K513qH295GXB-MZuHlZHo3e7lRvCDdHeCQi4mJr4nodA',
    'RAZORPAY_KEY_ID': 'rzp_test_TbrlMReRXsMgY6',
    'RAZORPAY_KEY_SECRET': 'UkBhByyF1s0eyXsbMXzMu8ES',
  };

  /// Initialize environment at app launch: attempts to load .env from rootBundle
  static Future<void> init() async {
    try {
      final content = await rootBundle.loadString('.env');
      final lines = content.split('\n');
      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty || line.startsWith('#')) continue;
        final eqIdx = line.indexOf('=');
        if (eqIdx > 0) {
          final k = line.substring(0, eqIdx).trim();
          var v = line.substring(eqIdx + 1).trim();
          if ((v.startsWith('"') && v.endsWith('"')) ||
              (v.startsWith("'") && v.endsWith("'"))) {
            v = v.substring(1, v.length - 1);
          }
          if (v.isNotEmpty) {
            _runtimeEnv[k] = v;
          }
        }
      }
    } catch (_) {
      // If asset loading fails (e.g. running in pure dart unit test), fallback to platform loader
    }

    // Merge platform IO / desktop loaded keys
    final platformKeys = getPlatformEnvMap();
    for (final entry in platformKeys.entries) {
      if (entry.value.isNotEmpty && !_runtimeEnv.containsKey(entry.key)) {
        _runtimeEnv[entry.key] = entry.value;
      }
    }
  }

  /// Get environment variable by key
  static String get(String key, {String fallback = ''}) {
    // 1. Check compile-time --dart-define or platform IO
    final platformVal = getEnvValue(key, fallback: '');
    if (_isValidValue(platformVal)) {
      return platformVal;
    }

    // 2. Check runtime loaded from rootBundle (.env asset in APK)
    if (_runtimeEnv.containsKey(key) && _isValidValue(_runtimeEnv[key])) {
      return _runtimeEnv[key]!;
    }

    // 3. Fallback to embedded project default
    if (defaultEnv.containsKey(key) && _isValidValue(defaultEnv[key])) {
      return defaultEnv[key]!;
    }

    // 4. Return caller-provided fallback if valid
    if (_isValidValue(fallback)) {
      return fallback;
    }

    return fallback;
  }

  static bool _isValidValue(String? val) {
    if (val == null) return false;
    final t = val.trim();
    return t.isNotEmpty &&
        !t.contains('YOUR_') &&
        !t.contains('your_') &&
        !t.contains('YOUR-');
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

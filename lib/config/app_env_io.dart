import 'dart:io';

final Map<String, String> _loadedEnv = _loadDotEnv();

Map<String, String> _loadDotEnv() {
  final map = <String, String>{};
  try {
    final candidates = [
      File('.env'),
      File('../.env'),
      File('${Directory.current.path}/.env'),
    ];

    for (final file in candidates) {
      if (file.existsSync()) {
        final lines = file.readAsLinesSync();
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
            map[k] = v;
          }
        }
        break; // Successfully loaded from the first existing .env file
      }
    }
  } catch (_) {}
  return map;
}

/// Retrieve environment value on IO platforms (VM, Desktop, tests, Mobile)
String getEnvValue(String key, {String fallback = ''}) {
  // 1. Check compile-time --dart-define or --dart-define-from-file
  final envVal = String.fromEnvironment(key);
  if (envVal.isNotEmpty) return envVal;

  // 2. Check locally loaded .env file
  if (_loadedEnv.containsKey(key) && _loadedEnv[key]!.isNotEmpty) {
    return _loadedEnv[key]!;
  }

  // 3. Fallback
  return fallback;
}

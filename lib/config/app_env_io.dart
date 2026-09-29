import 'dart:io';

const Map<String, String> _ioDefaultEnv = {
  'GOOGLE_MAPS_API_KEY': 'AIzaSyDjRpb6IFTB14FxzcTyAloPkDzbfI6On-8',
  'SUPABASE_URL': 'https://wntlcbyguyrbvzgihugi.supabase.co',
  'SUPABASE_ANON_KEY': 'sb_publishable_FC03eAb0E2Zp4l9MQoiu3g_v57SqqPP',
  'GEMINI_API_KEY': 'AQ.Ab8RN6K513qH295GXB-MZuHlZHo3e7lRvCDdHeCQi4mJr4nodA',
  'RAZORPAY_KEY_ID': 'rzp_test_TbrlMReRXsMgY6',
  'RAZORPAY_KEY_SECRET': 'UkBhByyF1s0eyXsbMXzMu8ES',
};

final Map<String, String> _loadedEnv = _loadDotEnv();

Map<String, String> getPlatformEnvMap() => _loadedEnv;

Map<String, String> _loadDotEnv() {
  final map = Map<String, String>.from(_ioDefaultEnv);
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
            if (v.isNotEmpty) {
              map[k] = v;
            }
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
  // 1. Check known compile-time --dart-define
  String envVal = '';
  switch (key) {
    case 'GOOGLE_MAPS_API_KEY':
      envVal = const String.fromEnvironment('GOOGLE_MAPS_API_KEY');
      break;
    case 'SUPABASE_URL':
      envVal = const String.fromEnvironment('SUPABASE_URL');
      break;
    case 'SUPABASE_ANON_KEY':
      envVal = const String.fromEnvironment('SUPABASE_ANON_KEY');
      break;
    case 'GEMINI_API_KEY':
      envVal = const String.fromEnvironment('GEMINI_API_KEY');
      break;
    case 'RAZORPAY_KEY_ID':
      envVal = const String.fromEnvironment('RAZORPAY_KEY_ID');
      break;
    case 'RAZORPAY_KEY_SECRET':
      envVal = const String.fromEnvironment('RAZORPAY_KEY_SECRET');
      break;
  }
  if (envVal.isNotEmpty && !envVal.contains('YOUR_') && !envVal.contains('your_')) {
    return envVal;
  }

  // 2. Check locally loaded .env file or default
  if (_loadedEnv.containsKey(key) && _loadedEnv[key]!.isNotEmpty) {
    final val = _loadedEnv[key]!;
    if (!val.contains('YOUR_') && !val.contains('your_')) {
      return val;
    }
  }

  // 3. Fallback
  return fallback;
}

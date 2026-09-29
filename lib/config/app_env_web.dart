const Map<String, String> _webDefaultEnv = {
  'GOOGLE_MAPS_API_KEY': 'AIzaSyDjRpb6IFTB14FxzcTyAloPkDzbfI6On-8',
  'SUPABASE_URL': 'https://wntlcbyguyrbvzgihugi.supabase.co',
  'SUPABASE_ANON_KEY': 'sb_publishable_FC03eAb0E2Zp4l9MQoiu3g_v57SqqPP',
  'GEMINI_API_KEY': 'AQ.Ab8RN6K513qH295GXB-MZuHlZHo3e7lRvCDdHeCQi4mJr4nodA',
  'RAZORPAY_KEY_ID': 'rzp_test_TbrlMReRXsMgY6',
  'RAZORPAY_KEY_SECRET': 'UkBhByyF1s0eyXsbMXzMu8ES',
};

Map<String, String> getPlatformEnvMap() => const {};

/// Web environment resolver (resolves compile-time --dart-define or fallback)
String getEnvValue(String key, {String fallback = ''}) {
  String val = '';
  switch (key) {
    case 'GOOGLE_MAPS_API_KEY':
      val = const String.fromEnvironment('GOOGLE_MAPS_API_KEY');
      break;
    case 'SUPABASE_URL':
      val = const String.fromEnvironment('SUPABASE_URL');
      break;
    case 'SUPABASE_ANON_KEY':
      val = const String.fromEnvironment('SUPABASE_ANON_KEY');
      break;
    case 'GEMINI_API_KEY':
      val = const String.fromEnvironment('GEMINI_API_KEY');
      break;
    case 'RAZORPAY_KEY_ID':
      val = const String.fromEnvironment('RAZORPAY_KEY_ID');
      break;
    case 'RAZORPAY_KEY_SECRET':
      val = const String.fromEnvironment('RAZORPAY_KEY_SECRET');
      break;
  }

  if (val.isNotEmpty && !val.contains('YOUR_') && !val.contains('your_')) {
    return val;
  }

  if (_webDefaultEnv.containsKey(key)) {
    return _webDefaultEnv[key]!;
  }

  return fallback;
}

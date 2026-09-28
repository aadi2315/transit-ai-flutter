/// Stub implementation for non-web, non-io platforms
String getEnvValue(String key, {String fallback = ''}) {
  switch (key) {
    case 'GOOGLE_MAPS_API_KEY':
      const val = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
      return val.isNotEmpty ? val : fallback;
    case 'SUPABASE_URL':
      const val = String.fromEnvironment('SUPABASE_URL');
      return val.isNotEmpty ? val : fallback;
    case 'SUPABASE_ANON_KEY':
      const val = String.fromEnvironment('SUPABASE_ANON_KEY');
      return val.isNotEmpty ? val : fallback;
    case 'GEMINI_API_KEY':
      const val = String.fromEnvironment('GEMINI_API_KEY');
      return val.isNotEmpty ? val : fallback;
    case 'RAZORPAY_KEY_ID':
      const val = String.fromEnvironment('RAZORPAY_KEY_ID');
      return val.isNotEmpty ? val : fallback;
    case 'RAZORPAY_KEY_SECRET':
      const val = String.fromEnvironment('RAZORPAY_KEY_SECRET');
      return val.isNotEmpty ? val : fallback;
    default:
      return fallback;
  }
}

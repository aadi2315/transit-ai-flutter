/// Web environment resolver (resolves compile-time --dart-define or fallback)
String getEnvValue(String key, {String fallback = ''}) {
  switch (key) {
    case 'GOOGLE_MAPS_API_KEY':
      const googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
      return googleMapsApiKey.isNotEmpty ? googleMapsApiKey : fallback;
    case 'SUPABASE_URL':
      const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
      return supabaseUrl.isNotEmpty ? supabaseUrl : fallback;
    case 'SUPABASE_ANON_KEY':
      const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
      return supabaseAnonKey.isNotEmpty ? supabaseAnonKey : fallback;
    case 'GEMINI_API_KEY':
      const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
      return geminiApiKey.isNotEmpty ? geminiApiKey : fallback;
    case 'RAZORPAY_KEY_ID':
      const razorpayKeyId = String.fromEnvironment('RAZORPAY_KEY_ID');
      return razorpayKeyId.isNotEmpty ? razorpayKeyId : fallback;
    case 'RAZORPAY_KEY_SECRET':
      const razorpayKeySecret = String.fromEnvironment('RAZORPAY_KEY_SECRET');
      return razorpayKeySecret.isNotEmpty ? razorpayKeySecret : fallback;
    default:
      return fallback;
  }
}

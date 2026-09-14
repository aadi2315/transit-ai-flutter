/// Configuration and API key storage for Google Gemini AI in Transit AI
///
/// WHERE THE GEMINI KEY IS STORED:
/// File Path: `lib/config/gemini_config.dart`
class GeminiConfig {
  /// Google Gemini API Key configured for live AI reasoning
  static String geminiApiKey =
      'YOUR_GEMINI_API_KEY';

  /// Returns true if a valid Google Gemini API Key is configured
  static bool get hasKey =>
      geminiApiKey.trim().isNotEmpty &&
      !geminiApiKey.contains('YOUR_') &&
      geminiApiKey.length > 15;

  /// Update the Gemini API key dynamically at runtime if needed
  static void setApiKey(String key) {
    geminiApiKey = key.trim();
  }

  /// Model identifier to use (Fast, low-latency, multimodal transit reasoning)
  static const String modelName = 'gemini-3.6-flash';

  /// List of compatible models in order of priority
  static const List<String> supportedModels = [
    'gemini-3.6-flash',
    'gemini-3.5-flash',
    'gemini-flash-latest',
    'gemini-2.5-flash-lite',
  ];
}

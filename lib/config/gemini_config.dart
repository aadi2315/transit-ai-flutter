/// Configuration and API key storage for Google Gemini AI in Transit AI
///
/// WHERE THE GEMINI KEY IS STORED:
/// File Path: `lib/config/gemini_config.dart`
///
/// You can paste your Gemini API key from Google AI Studio (https://aistudio.google.com/)
/// here in [geminiApiKey] or set it dynamically at runtime via the in-app Gemini settings modal.
class GeminiConfig {
  /// Paste your Google Gemini API Key here when ready:
  /// Example: 'AIzaSyYourActualGoogleGeminiApiKeyHere'
  static String geminiApiKey = '';

  /// Returns true if a valid Google Gemini API Key is configured
  static bool get hasKey =>
      geminiApiKey.trim().isNotEmpty &&
      !geminiApiKey.contains('YOUR_') &&
      geminiApiKey.length > 15;

  /// Update the Gemini API key dynamically from UI or at runtime
  static void setApiKey(String key) {
    geminiApiKey = key.trim();
  }

  /// Model identifier to use (Fast, low-latency, multimodal transit reasoning)
  static const String modelName = 'gemini-1.5-flash';

  static const String instructions = '''
To activate the live Gemini Chatbot in Transit AI:
1. Obtain a free API key from Google AI Studio: https://aistudio.google.com/
2. Paste the key in GeminiConfig.geminiApiKey or tap the 'Key' icon inside the AI Assistant modal.
3. The chatbot will instantly analyze all live database reports, route detours, and passenger inquiries.
''';
}

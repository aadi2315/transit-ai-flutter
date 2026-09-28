/// Stub implementation for non-web, non-io platforms
String getEnvValue(String key, {String fallback = ''}) {
  final envVal = String.fromEnvironment(key);
  if (envVal.isNotEmpty) return envVal;
  return fallback;
}

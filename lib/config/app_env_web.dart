/// Web environment resolver (resolves compile-time --dart-define or fallback)
String getEnvValue(String key, {String fallback = ''}) {
  final envVal = String.fromEnvironment(key);
  if (envVal.isNotEmpty) return envVal;
  return fallback;
}

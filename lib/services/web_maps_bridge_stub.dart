import 'dart:async';

/// Stub implementation for non-web platforms (e.g. Flutter VM / unit tests)
Future<Map<String, dynamic>?> queryJsDirections({
  required String origin,
  required String destination,
  List<String>? waypoints,
}) async {
  return null;
}

Future<List<Map<String, String>>> queryJsPlaces(String input) async {
  return [];
}

Future<Map<String, dynamic>?> queryJsCurrentLocation() async {
  return null;
}

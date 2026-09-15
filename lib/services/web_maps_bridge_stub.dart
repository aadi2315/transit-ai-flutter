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

bool initInteractiveMap(String divId, {bool isSatellite = false}) {
  return false;
}

bool updateInteractiveRoute(
  String divId,
  String polylineEnc,
  double? originLat,
  double? originLng,
  double? destLat,
  double? destLng,
) {
  return false;
}

void setInteractiveMapScope(String divId, String scope) {}

void setInteractiveMapType(String divId, bool isSatellite) {}

void zoomInteractiveMap(String divId, int delta) {}

void resetInteractiveMap(String divId) {}

void updateInteractiveGps(String divId, double lat, double lng) {}

void centerInteractiveGps(String divId, double lat, double lng) {}

bool updateTransitRoute(
  String divId,
  String legsJson, {
  double? originLat,
  double? originLng,
  double? destLat,
  double? destLng,
}) {
  return false;
}

void clearInteractiveRoute(String divId) {}

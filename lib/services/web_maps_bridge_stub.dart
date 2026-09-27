import 'dart:async';
import 'native_map_registry.dart';

/// Stub / Native VM implementation for non-web platforms (e.g. Flutter mobile APK / unit tests)
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
  return true;
}

bool updateInteractiveRoute(
  String divId,
  String polylineEnc,
  double? originLat,
  double? originLng,
  double? destLat,
  double? destLng,
) {
  return NativeMapRegistry.updateRoute(
    divId,
    polylineEnc,
    originLat,
    originLng,
    destLat,
    destLng,
  );
}

void setInteractiveMapScope(String divId, String scope) {
  NativeMapRegistry.setScope(divId, scope);
}

void setInteractiveMapType(String divId, bool isSatellite) {
  NativeMapRegistry.setType(divId, isSatellite);
}

void zoomInteractiveMap(String divId, int delta) {
  NativeMapRegistry.zoom(divId, delta);
}

void resetInteractiveMap(String divId) {
  NativeMapRegistry.reset(divId);
}

void updateInteractiveGps(String divId, double lat, double lng) {
  NativeMapRegistry.updateGps(divId, lat, lng);
}

void centerInteractiveGps(String divId, double lat, double lng) {
  NativeMapRegistry.centerGps(divId, lat, lng);
}

bool updateTransitRoute(
  String divId,
  String legsJson, {
  double? originLat,
  double? originLng,
  double? destLat,
  double? destLng,
}) {
  return NativeMapRegistry.updateTransitRoute(
    divId,
    legsJson,
    originLat: originLat,
    originLng: originLng,
    destLat: destLat,
    destLng: destLng,
  );
}

void clearInteractiveRoute(String divId) {
  NativeMapRegistry.clearRoute(divId);
}


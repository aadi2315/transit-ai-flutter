// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:js' as js;

/// Injects Google Maps JavaScript SDK dynamically using the configured API Key
void injectWebMapsSdk(String apiKey) {
  try {
    if (apiKey.trim().isNotEmpty &&
        !apiKey.contains('YOUR_') &&
        apiKey.length > 15) {
      if (js.context.hasProperty('loadGoogleMapsSdk')) {
        js.context.callMethod('loadGoogleMapsSdk', [apiKey]);
      }
    }
  } catch (_) {}
}

/// Web implementation using Google Maps JavaScript SDK bridge without CORS limitations
Future<Map<String, dynamic>?> queryJsDirections({
  required String origin,
  required String destination,
  List<String>? waypoints,
}) async {
  try {
    if (!js.context.hasProperty('transitGetDirections')) {
      return null;
    }

    final completer = Completer<Map<String, dynamic>?>();
    final wpJson = waypoints != null ? jsonEncode(waypoints) : '[]';

    js.context.callMethod('transitGetDirections', [
      origin,
      destination,
      wpJson,
      (dynamic rawResult) {
        try {
          final str = rawResult.toString();
          final map = jsonDecode(str) as Map<String, dynamic>;
          if (map['status'] == 'OK') {
            completer.complete(map);
          } else {
            completer.complete(null);
          }
        } catch (_) {
          completer.complete(null);
        }
      }
    ]);

    return await completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => null,
    );
  } catch (_) {
    return null;
  }
}

Future<List<Map<String, String>>> queryJsPlaces(String input) async {
  try {
    if (!js.context.hasProperty('transitGetPlacePredictions')) {
      return [];
    }

    final completer = Completer<List<Map<String, String>>>();

    js.context.callMethod('transitGetPlacePredictions', [
      input,
      (dynamic rawResult) {
        try {
          final str = rawResult.toString();
          final list = jsonDecode(str) as List<dynamic>;
          final results = <Map<String, String>>[];
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              results.add({
                'description': (item['description'] ?? '').toString(),
                'mainText': (item['mainText'] ?? '').toString(),
                'secondaryText': (item['secondaryText'] ?? '').toString(),
              });
            }
          }
          completer.complete(results);
        } catch (_) {
          completer.complete([]);
        }
      }
    ]);

    return await completer.future.timeout(
      const Duration(seconds: 4),
      onTimeout: () => [],
    );
  } catch (_) {
    return [];
  }
}

Future<Map<String, dynamic>?> queryJsCurrentLocation() async {
  try {
    if (!js.context.hasProperty('transitGetCurrentLocation')) {
      return null;
    }

    final completer = Completer<Map<String, dynamic>?>();

    js.context.callMethod('transitGetCurrentLocation', [
      (dynamic rawResult) {
        try {
          final str = rawResult.toString();
          final map = jsonDecode(str) as Map<String, dynamic>;
          if (map['status'] == 'OK') {
            completer.complete(map);
          } else {
            completer.complete(null);
          }
        } catch (_) {
          completer.complete(null);
        }
      }
    ]);

    return await completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => null,
    );
  } catch (_) {
    return null;
  }
}

/// Initializes interactive Google Map instance in the specified div element
bool initInteractiveMap(String divId, {bool isSatellite = false}) {
  try {
    if (js.context.hasProperty('transitInitMap')) {
      final res = js.context.callMethod('transitInitMap', [divId, isSatellite]);
      return res == true;
    }
  } catch (e) {
    // ignore
  }
  return false;
}

/// Renders or updates polyline and A/B markers on the interactive map
bool updateInteractiveRoute(
  String divId,
  String polylineEnc,
  double? originLat,
  double? originLng,
  double? destLat,
  double? destLng,
) {
  try {
    if (js.context.hasProperty('transitUpdateRoute')) {
      final res = js.context.callMethod('transitUpdateRoute', [
        divId,
        polylineEnc,
        originLat,
        originLng,
        destLat,
        destLng,
      ]);
      return res == true;
    }
  } catch (e) {
    // ignore
  }
  return false;
}

/// Changes map scope bounds ('corridor', 'city', 'metro')
void setInteractiveMapScope(String divId, String scope) {
  try {
    if (js.context.hasProperty('transitSetMapScope')) {
      js.context.callMethod('transitSetMapScope', [divId, scope]);
    }
  } catch (_) {}
}

/// Toggles between dark roadmap and satellite view
void setInteractiveMapType(String divId, bool isSatellite) {
  try {
    if (js.context.hasProperty('transitSetMapType')) {
      js.context.callMethod('transitSetMapType', [divId, isSatellite]);
    }
  } catch (_) {}
}

/// Increments or decrements zoom level
void zoomInteractiveMap(String divId, int delta) {
  try {
    if (js.context.hasProperty('transitZoomMap')) {
      js.context.callMethod('transitZoomMap', [divId, delta]);
    }
  } catch (_) {}
}

/// Resets view back to fit route bounds
void resetInteractiveMap(String divId) {
  try {
    if (js.context.hasProperty('transitResetMap')) {
      js.context.callMethod('transitResetMap', [divId]);
    }
  } catch (_) {}
}

/// Places or updates the live user GPS marker on the interactive map
void updateInteractiveGps(String divId, double lat, double lng) {
  try {
    if (js.context.hasProperty('transitUpdateGps')) {
      js.context.callMethod('transitUpdateGps', [divId, lat, lng]);
    }
  } catch (_) {}
}

/// Pans to and zooms in on user live GPS location
void centerInteractiveGps(String divId, double lat, double lng) {
  try {
    if (js.context.hasProperty('transitCenterOnGps')) {
      js.context.callMethod('transitCenterOnGps', [divId, lat, lng]);
    }
  } catch (_) {}
}

/// Renders a multi-leg transit route (bus lines with stop markers, transfer icons).
/// [legsJson] is a JSON-encoded list of leg objects: each has polylineEnc, color,
/// busNumber, boardLat, boardLng, boardName, alightLat, alightLng, alightName, isTransfer.
bool updateTransitRoute(
  String divId,
  String legsJson, {
  double? originLat,
  double? originLng,
  double? destLat,
  double? destLng,
}) {
  try {
    if (js.context.hasProperty('transitUpdateTransitRoute')) {
      final res = js.context.callMethod('transitUpdateTransitRoute', [
        divId,
        legsJson,
        originLat,
        originLng,
        destLat,
        destLng,
      ]);
      return res == true;
    }
  } catch (_) {}
  return false;
}

/// Clears all route polylines and markers from the map.
void clearInteractiveRoute(String divId) {
  try {
    if (js.context.hasProperty('transitClearRoute')) {
      js.context.callMethod('transitClearRoute', [divId]);
    }
  } catch (_) {}
}

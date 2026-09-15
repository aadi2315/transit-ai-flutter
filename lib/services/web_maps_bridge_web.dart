// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:js' as js;

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

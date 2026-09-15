import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transit_app/config/transit_map_config.dart';
import 'package:transit_app/services/transit_gps_service.dart';
import 'package:transit_app/services/transit_place_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Transit GPS Service & Location Model Tests', () {
    test('TransitGpsService returns valid fallback or live coordinates', () async {
      final loc = await TransitGpsService.instance.getCurrentLocation();
      expect(loc.latitude, isNotNull);
      expect(loc.longitude, isNotNull);
      expect(loc.accuracy, greaterThan(0));
      expect(loc.formattedCoords.contains('° N'), isTrue);
      expect(loc.formattedCoords.contains('° E'), isTrue);
      expect(loc.accuracyLabel.startsWith('±'), isTrue);
    });

    test('TransitGpsLocation formats coordinates and accuracy labels accurately', () {
      final loc = TransitGpsLocation(
        latitude: 23.0827,
        longitude: 72.5284,
        accuracy: 5.4,
        timestamp: DateTime.now(),
      );
      expect(loc.formattedCoords, '23.0827° N, 72.5284° E');
      expect(loc.accuracyLabel, '±5m');
      expect(loc.toJson()['latitude'], 23.0827);
    });
  });

  group('Google Static Maps GPS Marker & Scope URL Tests', () {
    test('buildStaticMapUrl embeds cyan live GPS pin when user coordinates are provided', () {
      final url = TransitMapConfig.buildStaticMapUrl(
        encodedPolyline: '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
        originLat: 23.0827,
        originLng: 72.5284,
        destLat: 23.0315,
        destLng: 72.5074,
        userLat: 23.0850,
        userLng: 72.5300,
      );

      expect(url.contains('&markers=color:0x00e5ff%7Csize:mid%7C23.085,72.53'), isTrue);
    });

    test('buildStaticMapUrl embeds center and zoom for City Grid and Metro scopes', () {
      final cityUrl = TransitMapConfig.buildStaticMapUrl(
        encodedPolyline: '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
        centerLat: TransitMapConfig.ahmedabadCenterLat,
        centerLng: TransitMapConfig.ahmedabadCenterLng,
        zoomLevel: TransitMapConfig.cityScopeZoom,
      );

      expect(cityUrl.contains('&center=${TransitMapConfig.ahmedabadCenterLat},${TransitMapConfig.ahmedabadCenterLng}'), isTrue);
      expect(cityUrl.contains('&zoom=${TransitMapConfig.cityScopeZoom}'), isTrue);

      final metroUrl = TransitMapConfig.buildStaticMapUrl(
        encodedPolyline: '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
        centerLat: TransitMapConfig.metroRegionCenterLat,
        centerLng: TransitMapConfig.metroRegionCenterLng,
        zoomLevel: TransitMapConfig.metroScopeZoom,
      );

      expect(metroUrl.contains('&center=${TransitMapConfig.metroRegionCenterLat},${TransitMapConfig.metroRegionCenterLng}'), isTrue);
      expect(metroUrl.contains('&zoom=${TransitMapConfig.metroScopeZoom}'), isTrue);
    });
  });

  group('Place Autocomplete GPS Suggestion Tests', () {
    test('TransitPlaceService returns Current Location (Live GPS) as top suggestion for empty query', () async {
      final suggestions = await TransitPlaceService.instance.getSuggestions('');
      expect(suggestions.isNotEmpty, isTrue);
      expect(suggestions.first.type, 'gps');
      expect(suggestions.first.name, contains('Current Location'));
      expect(suggestions.first.icon, Icons.my_location_rounded);
      expect(suggestions.first.iconColor, const Color(0xFF00E5FF));
    });

    test('TransitPlaceService suggests Current Location when typing "gps" or "location"', () async {
      final suggestions = await TransitPlaceService.instance.getSuggestions('gps');
      expect(suggestions.any((s) => s.type == 'gps'), isTrue);
    });
  });
}

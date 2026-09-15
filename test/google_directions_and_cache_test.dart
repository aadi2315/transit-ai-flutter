import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:transit_app/config/transit_map_config.dart';
import 'package:transit_app/services/google_directions_service.dart';

void main() {
  group('TransitMapConfig & Google Maps Key Tests', () {
    test('TransitMapConfig holds valid configured Google Maps API Key', () {
      expect(TransitMapConfig.googleMapsApiKey, equals('YOUR_GOOGLE_MAPS_API_KEY'));
      expect(TransitMapConfig.hasGoogleMapsApiKey, isTrue);
    });

    test('buildDirectionsApiUrl strictly enforces DRIVING mode and waypoints', () {
      final url = TransitMapConfig.buildDirectionsApiUrl(
        origin: 'Sola Bhagwat',
        destination: 'Iskcon Cross Road',
        waypoints: ['Shivranjani'],
      );

      expect(url.contains('mode=driving'), isTrue, reason: 'Must use DRIVING mode, NOT transit mode');
      expect(url.contains('key=YOUR_GOOGLE_MAPS_API_KEY'), isTrue);
      expect(url.contains('origin=Sola%20Bhagwat'), isTrue);
      expect(url.contains('destination=Iskcon%20Cross%20Road'), isTrue);
      expect(url.contains('waypoints=Shivranjani'), isTrue);
    });

    test('buildStaticMapUrl constructs roadmap and satellite image URLs', () {
      final staticUrl = TransitMapConfig.buildStaticMapUrl(
        encodedPolyline: 'test_poly_123',
        originLat: 23.0827,
        originLng: 72.5284,
        destLat: 23.0315,
        destLng: 72.5074,
      );

      expect(staticUrl.contains('https://maps.googleapis.com/maps/api/staticmap'), isTrue);
      expect(staticUrl.contains('enc:test_poly_123'), isTrue);
      expect(staticUrl.contains('23.0827,72.5284'), isTrue);
      expect(staticUrl.contains('23.0315,72.5074'), isTrue);
    });
  });

  group('Google Polyline Encoding & Decoding Tests', () {
    test('Decodes Google polyline string into accurate geographic coordinates', () {
      // Standard Google polyline string
      const samplePolyline = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';
      final decoded = GoogleDirectionsService.decodePolyline(samplePolyline);

      expect(decoded.isNotEmpty, isTrue);
      expect(decoded.length, equals(3));
      expect(decoded.first.latitude, closeTo(38.5, 0.1));
      expect(decoded.first.longitude, closeTo(-120.2, 0.1));
    });

    test('Encodes and decodes coordinates with round-trip fidelity', () {
      final originalPoints = [
        const MapCoordinate(23.0827, 72.5284), // Sola Bhagwat
        const MapCoordinate(23.0560, 72.5210), // Gulab Tower
        const MapCoordinate(23.0234, 72.5312), // Shivranjani
        const MapCoordinate(23.0315, 72.5074), // Iskcon
      ];

      final encoded = GoogleDirectionsService.encodePolyline(originalPoints);
      expect(encoded.isNotEmpty, isTrue);

      final decoded = GoogleDirectionsService.decodePolyline(encoded);
      expect(decoded.length, equals(originalPoints.length));

      for (int i = 0; i < originalPoints.length; i++) {
        expect(decoded[i].latitude, closeTo(originalPoints[i].latitude, 0.0001));
        expect(decoded[i].longitude, closeTo(originalPoints[i].longitude, 0.0001));
      }
    });

    test('Handles empty polyline gracefully without throwing', () {
      final emptyResult = GoogleDirectionsService.decodePolyline('');
      expect(emptyResult, isEmpty);
    });
  });

  group('GoogleDirectionsService Fetch & Directions API Tests', () {
    test('Parses Google Directions API HTTP response in DRIVING mode', () async {
      final mockResponseJson = {
        'status': 'OK',
        'routes': [
          {
            'overview_polyline': {
              'points': 'm}reDe_svMz@|@bAhAnBpBhDhDnEnEfF|FhGhG|G~G`H|HjInIpJvJ~J`K|KjLlM~MnN`O|OhPtP~P',
            },
            'legs': [
              {
                'distance': {'text': '11.4 km', 'value': 11400},
                'duration': {'text': '26 mins', 'value': 1560},
                'start_location': {'lat': 23.0827, 'lng': 72.5284},
                'end_location': {'lat': 23.0315, 'lng': 72.5074},
                'steps': [
                  {
                    'html_instructions': 'Head <b>south</b> on <b>SG Highway</b>',
                    'distance': {'text': '6.8 km'},
                    'duration': {'text': '15 mins'},
                    'start_location': {'lat': 23.0827, 'lng': 72.5284},
                    'end_location': {'lat': 23.0450, 'lng': 72.5220},
                  },
                  {
                    'html_instructions': 'Turn <b>right</b> onto <b>132 Feet Ring Road</b>',
                    'distance': {'text': '4.6 km'},
                    'duration': {'text': '11 mins'},
                    'start_location': {'lat': 23.0450, 'lng': 72.5220},
                    'end_location': {'lat': 23.0315, 'lng': 72.5074},
                  },
                ],
              },
            ],
          },
        ],
      };

      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['mode'], equals('driving'));
        expect(request.url.queryParameters['key'], equals('YOUR_GOOGLE_MAPS_API_KEY'));
        return http.Response(jsonEncode(mockResponseJson), 200);
      });

      final result = await GoogleDirectionsService.instance.fetchDrivingRoute(
        origin: 'Sola Bhagwat (BRTS Hub)',
        destination: 'Iskcon Cross Road',
        waypoints: ['Shivranjani Cross Road'],
        httpClient: mockClient,
      );

      expect(result.distanceKm, equals(11.4));
      expect(result.durationMins, equals(26));
      expect(result.fareAmount, equals(9.00));
      expect(result.steps.length, equals(2));
      expect(result.steps[0].plainInstruction, equals('Head south on SG Highway'));
      expect(result.polylineCoordinates.isNotEmpty, isTrue);
      expect(result.isFromSupabaseCache, isFalse);
    });

    test('Parses Supabase cached route record into TransitRouteResult', () {
      final supabaseRecord = {
        'route_id': 'ROUTE_SOLA_ISKCON',
        'route_short_name': 'BRTS 9U ➔ BRTS 8D',
        'origin_name': 'Sola Bhagwat (BRTS Hub)',
        'destination_name': 'Iskcon Cross Road',
        'waypoints': ['Shivranjani Cross Road'],
        'distance_km': 11.4,
        'duration_mins': 26,
        'fare_amount': 9.00,
        'encoded_polyline': 'm}reDe_svMz@|@bAhAnBpBhDhDnEnEfF|FhGhG|G~G`H|HjInIpJvJ~J`K|KjLlM~MnN`O|OhPtP~P',
        'route_steps': [
          {
            'instruction': 'Board BRTS 9U at Sola Bhagwat Platform 1',
            'distance': '6.8 km',
            'duration': '16 mins',
            'start': {'lat': 23.0827, 'lng': 72.5284},
            'end': {'lat': 23.0234, 'lng': 72.5312},
          }
        ],
      };

      final parsed = TransitRouteResult.fromSupabase(supabaseRecord);
      expect(parsed.origin, equals('Sola Bhagwat (BRTS Hub)'));
      expect(parsed.destination, equals('Iskcon Cross Road'));
      expect(parsed.distanceKm, equals(11.4));
      expect(parsed.fareAmount, equals(9.00));
      expect(parsed.isFromSupabaseCache, isTrue);
      expect(parsed.steps.length, equals(1));
    });
  });
}

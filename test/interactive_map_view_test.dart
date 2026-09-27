import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:transit_app/services/google_directions_service.dart';
import 'package:transit_app/services/transit_gps_service.dart';
import 'package:transit_app/services/web_maps_bridge.dart';
import 'package:transit_app/widgets/interactive_google_map_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Native Interactive Map View & Registry Tests', () {
    const testDivId = 'test_map_corridor';

    final testRoute = TransitRouteResult(
      origin: 'Sola Bhagwat',
      destination: 'Science City',
      originLat: 23.0827,
      originLng: 72.5284,
      destLat: 23.0315,
      destLng: 72.5074,
      encodedPolyline: GoogleDirectionsService.encodePolyline(const [
        MapCoordinate(23.0827, 72.5284),
        MapCoordinate(23.0571, 72.5179),
        MapCoordinate(23.0315, 72.5074),
      ]),
      polylineCoordinates: const [
        MapCoordinate(23.0827, 72.5284),
        MapCoordinate(23.0571, 72.5179),
        MapCoordinate(23.0315, 72.5074),
      ],
      distanceKm: 6.2,
      distanceText: '6.2 km',
      durationMins: 20,
      durationText: '20 mins',
      fareAmount: 10.0,
      steps: const [],
    );

    final testGps = TransitGpsLocation(
      latitude: 23.0827,
      longitude: 72.5284,
      accuracy: 4.5,
      timestamp: DateTime.now(),
    );

    testWidgets('Renders FlutterMap with TileLayer, PolylineLayer, and MarkerLayer', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 600,
              child: InteractiveGoogleMapView(
                divId: testDivId,
                route: testRoute,
                gpsLocation: testGps,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byType(TileLayer), findsOneWidget);
      expect(find.byType(PolylineLayer), findsOneWidget);
      expect(find.byType(MarkerLayer), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('Sola Bhagwat'), findsOneWidget);
      expect(find.text('Science City'), findsOneWidget);

      // Tap marker B to trigger interactive InfoWindow popup
      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();

      expect(find.text('Focus Stop'), findsOneWidget);
      expect(find.text('Accessible entrance'), findsOneWidget);

      // Close popup
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Focus Stop'), findsNothing);
    });

    testWidgets('Responds to web_maps_bridge zoom, scope, satellite and reset controls', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: InteractiveGoogleMapView(
                divId: testDivId,
                route: testRoute,
                gpsLocation: testGps,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Zoom In and Out via bridge
      expect(() => zoomInteractiveMap(testDivId, 1), returnsNormally);
      expect(() => zoomInteractiveMap(testDivId, -1), returnsNormally);

      // Reset camera via bridge
      expect(() => resetInteractiveMap(testDivId), returnsNormally);

      // Scope change via bridge
      expect(() => setInteractiveMapScope(testDivId, 'city'), returnsNormally);
      expect(() => setInteractiveMapScope(testDivId, 'metro'), returnsNormally);
      expect(() => setInteractiveMapScope(testDivId, 'corridor'), returnsNormally);

      // Satellite toggle via bridge
      expect(() => setInteractiveMapType(testDivId, true), returnsNormally);
      await tester.pump();
      expect(() => setInteractiveMapType(testDivId, false), returnsNormally);
      await tester.pump();

      // GPS update and center
      expect(() => updateInteractiveGps(testDivId, 23.0850, 72.5300), returnsNormally);
      expect(() => centerInteractiveGps(testDivId, 23.0850, 72.5300), returnsNormally);
    });

    testWidgets('Renders multimodal transit legs from transitResultJson', (tester) async {
      final transitJson = jsonEncode([
        {
          'polylineEnc': GoogleDirectionsService.encodePolyline(const [
            MapCoordinate(23.0827, 72.5284),
            MapCoordinate(23.0600, 72.5200),
          ]),
          'color': '#1A73E8',
          'busNumber': '9U',
          'boardLat': 23.0827,
          'boardLng': 72.5284,
          'boardName': 'Sola Bhagwat',
          'alightLat': 23.0600,
          'alightLng': 72.5200,
          'alightName': 'Sola Bridge',
          'isTransfer': false,
        },
        {
          'polylineEnc': GoogleDirectionsService.encodePolyline(const [
            MapCoordinate(23.0600, 72.5200),
            MapCoordinate(23.0315, 72.5074),
          ]),
          'color': '#EA4335',
          'busNumber': '8D',
          'boardLat': 23.0600,
          'boardLng': 72.5200,
          'boardName': 'Sola Bridge',
          'alightLat': 23.0315,
          'alightLng': 72.5074,
          'alightName': 'Science City',
          'isTransfer': true,
        },
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 600,
              child: InteractiveGoogleMapView(
                divId: 'transit_legs_map',
                route: testRoute,
                transitResultJson: transitJson,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.text('8D'), findsWidgets); // Transfer bus badge & route midpoint badge
      expect(find.text('9U'), findsOneWidget); // Route midpoint badge for Leg 1
    });
  });
}


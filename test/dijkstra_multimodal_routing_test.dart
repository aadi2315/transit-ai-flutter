import 'package:flutter_test/flutter_test.dart';
import 'package:transit_app/domain/models/transit_graph_models.dart';
import 'package:transit_app/domain/engines/dijkstra_router.dart';
import 'package:transit_app/domain/engines/route_polyline_slicer.dart';
import 'package:transit_app/presentation/map/route_map_segment_builder.dart';
import 'package:transit_app/services/transit_routing_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Multimodal Dijkstra Transit Routing Engine', () {
    test('TransitRoutingService initializes and finds Sola Bhagwat -> Science City transfer', () async {
      final service = TransitRoutingService.instance;
      final ready = await service.init();
      expect(ready, isTrue);
      expect(service.isReady, isTrue);
      expect(service.allStops.length, greaterThanOrEqualTo(69));

      // Test 1: Sola Bhagwat (9U) to Science City (8D)
      final result = await service.findRoute(
        originStopId: 'STOP_SOLA_BHAGWAT',
        destinationStopId: 'STOP_SCIENCE_CITY',
      );

      expect(result, isNotNull);
      expect(result!.requiresTransfer, isTrue);
      expect(result.legs.length, equals(2));
      expect(result.busNumbers, containsAll(['9U', '8D']));
      expect(result.transferPoints.length, equals(1));
      
      // Boarding on 9U at Sola Bhagwat
      expect(result.legs[0].routeShortName, equals('9U'));
      expect(result.legs[0].boardStop.stopId, equals('STOP_SOLA_BHAGWAT'));
      
      // Transfer point is either Sola Bridge or Science City Approach
      final transferStopId = result.legs[0].alightStop.stopId;
      expect(
        ['STOP_SOLA_BRIDGE', 'STOP_SCIENCE_CITY_APPROACH'].contains(transferStopId),
        isTrue,
      );

      // Second leg on 8D to Science City
      expect(result.legs[1].routeShortName, equals('8D'));
      expect(result.legs[1].boardStop.stopId, equals(transferStopId));
      expect(result.legs[1].alightStop.stopId, equals('STOP_SCIENCE_CITY'));

      // Sliced display segments verify map clipping
      expect(result.displaySegments.length, equals(2));
      expect(result.displaySegments[0].polyline.length, greaterThan(1));
      expect(result.displaySegments[1].polyline.length, greaterThan(1));
    });

    test('Single-leg direct routing on 9U (no transfer required)', () async {
      final service = TransitRoutingService.instance;
      await service.init();

      final result = await service.findRoute(
        originStopId: 'STOP_VASANTNAGAR_TOWNSHIP',
        destinationStopId: 'STOP_SOLA_BRIDGE',
      );

      expect(result, isNotNull);
      expect(result!.requiresTransfer, isFalse);
      expect(result.legs.length, equals(1));
      expect(result.busNumbers, equals(['9U']));
      expect(result.transferPoints, isEmpty);
      expect(result.legs[0].boardStop.stopId, equals('STOP_VASANTNAGAR_TOWNSHIP'));
      expect(result.legs[0].alightStop.stopId, equals('STOP_SOLA_BRIDGE'));
    });

    test('Single-leg direct routing on 8D (Naroda Gam to Science City)', () async {
      final service = TransitRoutingService.instance;
      await service.init();

      final result = await service.findRoute(
        originStopId: 'STOP_NARODA_GAM',
        destinationStopId: 'STOP_SCIENCE_CITY',
      );

      expect(result, isNotNull);
      expect(result!.requiresTransfer, isFalse);
      expect(result.legs.length, equals(1));
      expect(result.busNumbers, equals(['8D']));
      expect(result.transferPoints, isEmpty);
      expect(result.legs[0].boardStop.stopId, equals('STOP_NARODA_GAM'));
      expect(result.legs[0].alightStop.stopId, equals('STOP_SCIENCE_CITY'));
    });

    test('RoutePolylineSlicer correctly projects and clips coordinates', () {
      final testPoints = [
        const LatLon(23.00, 72.00),
        const LatLon(23.10, 72.10),
        const LatLon(23.20, 72.20),
        const LatLon(23.30, 72.30),
      ];
      final shape = RouteShape(routeId: 'TEST_ROUTE', points: testPoints);
      const board = Stop(stopId: 'B', name: 'Board', lat: 23.09, lon: 72.09);
      const alight = Stop(stopId: 'A', name: 'Alight', lat: 23.21, lon: 72.21);

      final clipped = RoutePolylineSlicer.sliceForLeg(
        shape: shape,
        boardStop: board,
        alightStop: alight,
      );

      expect(clipped.length, greaterThanOrEqualTo(2));
      // First point should be close to board
      expect((clipped.first.lat - board.lat).abs(), lessThan(0.02));
      // Last point should be close to alight
      expect((clipped.last.lat - alight.lat).abs(), lessThan(0.02));
    });

    test('TransitRouter direct graph pathfinding', () {
      final router = TransitRouter.fromLists(
        stops: const [
          Stop(stopId: 'A', name: 'Stop A', lat: 23.0, lon: 72.0),
          Stop(stopId: 'B', name: 'Stop B', lat: 23.1, lon: 72.1),
        ],
        sequences: const [
          RouteStopSequence(
            routeId: 'R1',
            routeShortName: '1',
            stopIdsInOrder: ['A', 'B'],
          ),
        ],
      );
      final it = router.route(originStopId: 'A', destinationStopId: 'B');
      expect(it, isNotNull);
      expect(it!.legs.length, equals(1));
    });

    test('RouteMapSegmentBuilder outputs distinct colors and transfer markers', () {
      const stop1 = Stop(stopId: 'S1', name: 'Stop 1', lat: 23.0, lon: 72.0);
      const stop2 = Stop(stopId: 'S2', name: 'Stop 2', lat: 23.1, lon: 72.1);
      const stop3 = Stop(stopId: 'S3', name: 'Stop 3', lat: 23.2, lon: 72.2);

      const itinerary = Itinerary(
        legs: [
          TripLeg(
            routeId: 'R1',
            routeShortName: '9U',
            boardStopId: 'S1',
            alightStopId: 'S2',
            estimatedSeconds: 300,
          ),
          TripLeg(
            routeId: 'R2',
            routeShortName: '8D',
            boardStopId: 'S2',
            alightStopId: 'S3',
            estimatedSeconds: 400,
          ),
        ],
        estimatedTotalSeconds: 700,
      );

      final stopsMap = {'S1': stop1, 'S2': stop2, 'S3': stop3};
      final shapesMap = <String, RouteShape>{};

      final displaySegments = RouteMapSegmentBuilder.buildDisplaySegments(
        itinerary: itinerary,
        stopsById: stopsMap,
        shapesByRouteId: shapesMap,
      );

      expect(displaySegments.length, equals(2));
      expect(displaySegments[0].routeShortName, equals('9U'));
      expect(displaySegments[1].routeShortName, equals('8D'));
      // Segment 0 alight is a transfer point
      expect(displaySegments[0].alightMarker.isTransferPoint, isTrue);
      // Segment 1 board is a transfer point
      expect(displaySegments[1].boardMarker.isTransferPoint, isTrue);
      // Colors are distinct
      expect(displaySegments[0].colorArgb, isNot(equals(displaySegments[1].colorArgb)));
    });
  });
}

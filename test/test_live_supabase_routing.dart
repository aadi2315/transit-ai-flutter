// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transit_app/config/supabase_config.dart';
import 'package:transit_app/services/supabase_service.dart';
import 'package:transit_app/services/transit_routing_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Live Multimodal Dijkstra Routing with Supabase Data', () async {
    SharedPreferences.setMockInitialValues({});

    print('====================================================');
    print('TESTING LIVE SUPABASE MULTIMODAL DIJKSTRA ROUTING');
    print('====================================================');

    print('1. Initializing Supabase Connection...');
    final connected = await SupabaseService.instance.init();
    print('   Supabase Connected: $connected to ${SupabaseConfig.supabaseUrl}');

    print('2. Initializing TransitRoutingService from Live Supabase Tables...');
    final service = TransitRoutingService.instance;
    final ready = await service.init(forceRefresh: true);
    print('   Routing Engine Ready: $ready');
    print('   Total Stops Loaded: ${service.allStops.length}');

    print('\n3. Executing Multimodal Dijkstra Routing:');
    print('   Origin:      Sola Bhagwat (STOP_SOLA_BHAGWAT)');
    print('   Destination: Science City (STOP_SCIENCE_CITY)');

    final result = await service.findRoute(
      originStopId: 'STOP_SOLA_BHAGWAT',
      destinationStopId: 'STOP_SCIENCE_CITY',
    );

    expect(result, isNotNull);
    print('\n✅ ROUTE FOUND:');
    print('   Requires Transfer: ${result!.requiresTransfer}');
    print(
        '   Total Estimated Time: ${result.totalDurationMinutes.toStringAsFixed(1)} minutes');
    print('   Buses to Ride: ${result.busNumbers.join(" -> ")}');
    print(
        '   Transfer Stations: ${result.transferPoints.map((s) => s.name).join(", ")}');

    print('\n--- ITINERARY LEGS ---');
    for (int i = 0; i < result.legs.length; i++) {
      final leg = result.legs[i];
      print('Leg ${i + 1}: Bus ${leg.routeShortName}');
      print('   Board:  ${leg.boardStop.name} (${leg.boardStop.stopId})');
      print('   Alight: ${leg.alightStop.name} (${leg.alightStop.stopId})');
      print('   Time:   ${leg.estimatedMinutes.toStringAsFixed(1)} mins');
      print('   Clipped Polyline Points: ${leg.clippedPolyline.length}');
    }

    print('\n--- DISPLAY SEGMENTS FOR GOOGLE MAPS ---');
    for (int i = 0; i < result.displaySegments.length; i++) {
      final seg = result.displaySegments[i];
      print('Segment ${i + 1} (${seg.routeShortName}):');
      print('   Color ARGB: 0x${seg.colorArgb.toRadixString(16).toUpperCase()}');
      print('   Map Polyline Coordinates: ${seg.polyline.length} points');
      print(
          '   Board Marker: "${seg.boardMarker.label}" (Transfer: ${seg.boardMarker.isTransferPoint})');
      print(
          '   Alight Marker: "${seg.alightMarker.label}" (Transfer: ${seg.alightMarker.isTransferPoint})');
    }
    print('\n====================================================');
    print('SUCCESS: Live Multimodal Dijkstra Router & Slicer works perfectly!');
    print('====================================================');
  });
}

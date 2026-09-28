import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transit_app/screens/stitch_payment_qr_screen.dart';
import 'package:transit_app/services/google_directions_service.dart';
import 'package:transit_app/services/transit_routing_service.dart';
import 'package:transit_app/domain/models/transit_graph_models.dart';
import 'package:transit_app/theme/stitch_theme.dart';
import 'package:transit_app/core/storage/local_transit_vault.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await LocalTransitVault.instance.clearActiveTicket();
  });

  tearDown(() async {
    await LocalTransitVault.instance.clearActiveTicket();
  });

  testWidgets(
      'StitchPaymentQrScreen dynamically displays searched route (Sola Bhagwat to Science City ₹10.00)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final sampleRoute = TransitRouteResult(
      origin: 'Sola Bhagwat',
      destination: 'Science City',
      originLat: 23.085,
      originLng: 72.525,
      destLat: 23.075,
      destLng: 72.510,
      encodedPolyline: '',
      polylineCoordinates: [],
      distanceKm: 6.2,
      distanceText: '6.2 km',
      durationMins: 20,
      durationText: '20 mins',
      fareAmount: 10.0,
      steps: [],
    );

    const stop1 = Stop(stopId: 'sola', name: 'Sola Bhagwat', lat: 23.085, lon: 72.525);
    const stop2 = Stop(stopId: 'high_court', name: 'High Court of Gujarat', lat: 23.078, lon: 72.528);
    const stop3 = Stop(stopId: 'science_city', name: 'Science City', lat: 23.075, lon: 72.510);

    const legDetail1 = TripLegDetail(
      routeId: '9U',
      routeShortName: '9U',
      boardStop: stop1,
      alightStop: stop2,
      estimatedMinutes: 9.0,
      clippedPolyline: [],
    );

    const legDetail2 = TripLegDetail(
      routeId: '8D',
      routeShortName: '8D',
      boardStop: stop2,
      alightStop: stop3,
      estimatedMinutes: 11.0,
      clippedPolyline: [],
    );

    const tripLeg1 = TripLeg(
      routeId: '9U',
      routeShortName: '9U',
      boardStopId: 'sola',
      alightStopId: 'high_court',
      estimatedSeconds: 540.0,
    );
    const tripLeg2 = TripLeg(
      routeId: '8D',
      routeShortName: '8D',
      boardStopId: 'high_court',
      alightStopId: 'science_city',
      estimatedSeconds: 660.0,
    );

    final sampleTransitResult = TransitRoutingResult(
      itinerary: const Itinerary(legs: [tripLeg1, tripLeg2], estimatedTotalSeconds: 1200.0),
      displaySegments: const [],
      legs: const [legDetail1, legDetail2],
      busNumbers: const ['9U', '8D'],
      transferPoints: const [stop2],
      totalDurationMinutes: 20.0,
      requiresTransfer: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: StitchTheme.lightTheme,
        home: Scaffold(
          body: StitchPaymentQrScreen(
            onNavigateToHome: () {},
            onNavigateToRouteDetails: () {},
            onNavigateToAskRoute: () {},
            onNavigateToPasses: () {},
            onNavigateToProfile: () {},
            isDarkMode: false,
            activeRoute: sampleRoute,
            activeTransitResult: sampleTransitResult,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify origin and destination are dynamically rendered
    expect(find.text('Sola Bhagwat → Science City'), findsAtLeastNWidgets(1));

    // Verify distance and duration text
    expect(find.textContaining('6.2 km • ~20 mins'), findsOneWidget);

    // Verify dynamic unified total fare
    expect(find.text('INR ₹10.00'), findsOneWidget);

    // Verify Pay CTA dynamic button text
    expect(find.text('Pay ₹10.00 via Google Pay'), findsOneWidget);

    // Verify legs breakdown has 9U and 8D
    expect(find.text('9U'), findsWidgets);
    expect(find.text('8D'), findsWidgets);

    // Verify Dedicated UPI Payment QR Section exists with dynamic amount
    expect(find.text('Pay via UPI QR Code'), findsOneWidget);
    expect(find.textContaining('Fare: ₹10.00'), findsOneWidget);

    // Verify simulation clearance button in UPI QR card
    final simulateUpiPayBtn =
        find.text('Confirm / Simulate UPI QR Payment Received');
    expect(simulateUpiPayBtn, findsOneWidget);

    await tester.ensureVisible(simulateUpiPayBtn);
    await tester.pump();
    await tester.tap(simulateUpiPayBtn);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // Verify ticket view now shows dynamic paid status
    expect(find.text('PRAVHA Dynamic Pass'), findsOneWidget);
    expect(find.text('CONFIRMED'), findsOneWidget);
    expect(find.text('₹10.00 Paid'), findsOneWidget);
    expect(find.text('AC Electric • 9U ➔ 8D'), findsOneWidget);
    expect(find.text('Sola Bhagwat'), findsAtLeastNWidgets(1));
    expect(find.text('Science City'), findsAtLeastNWidgets(1));
  });
}

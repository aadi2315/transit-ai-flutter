import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transit_app/screens/stitch_passes_screen.dart';

void main() {
  testWidgets('StitchPassesScreen displays dropdown pass selector and dynamic cost', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: StitchPassesScreen(
          onNavigateToHome: () {},
          onNavigateToRouteDetails: () {},
          onNavigateToAskRoute: () {},
          onNavigateToWallet: () {},
          onNavigateToProfile: () {},
          isDarkMode: false,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify header and pass selector title
    expect(find.text('PRAVHA Passes'), findsOneWidget);
    expect(find.text('Select Transit Pass'), findsOneWidget);
    expect(find.text('AMTS • BRTS • GSRTC Corridors'), findsOneWidget);

    // Verify operator chips
    expect(find.text('All'), findsOneWidget);
    expect(find.text('BRTS'), findsWidgets);
    expect(find.text('AMTS'), findsOneWidget);
    expect(find.text('GSRTC'), findsOneWidget);

    // Initial pass is BRTS Monthly Corridor Pass (₹750)
    expect(find.text('Monthly Corridor Pass'), findsOneWidget);
    expect(find.text('₹750'), findsWidgets);

    // Tap on AMTS filter chip
    await tester.tap(find.text('AMTS'));
    await tester.pumpAndSettle();

    // After selecting AMTS, the dropdown switches to an AMTS pass
    expect(find.text('Monthly "Travel as You Like"'), findsOneWidget);
    expect(find.text('₹900'), findsWidgets);
    expect(find.text('Pay ₹900 via UPI & Activate Pass'), findsOneWidget);

    // Tap on GSRTC filter chip
    await tester.tap(find.text('GSRTC'));
    await tester.pumpAndSettle();

    // After selecting GSRTC, it switches to a GSRTC pass
    expect(find.text('Point-to-Point Commuter Pass'), findsOneWidget);
    expect(find.text('₹800'), findsWidgets);
    expect(find.text('Pay ₹800 via UPI & Activate Pass'), findsOneWidget);
  });
}

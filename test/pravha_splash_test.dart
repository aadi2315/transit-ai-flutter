import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transit_app/screens/pravha_splash_screen.dart';

void main() {
  testWidgets('PravhaSplashScreen displays logo with driveIn and dismisses',
      (WidgetTester tester) async {
    bool finished = false;

    await tester.pumpWidget(
      MaterialApp(
        home: PravhaSplashScreen(
          autoDismiss: true,
          autoDismissDelay: const Duration(milliseconds: 500),
          onFinish: () {
            finished = true;
          },
        ),
      ),
    );

    // Initial frame
    expect(find.byType(PravhaSplashScreen), findsOneWidget);
    expect(find.text('Tap anywhere to enter'), findsOneWidget);

    // Advance time past autoDismissDelay
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 300));

    expect(finished, isTrue);
  });
}

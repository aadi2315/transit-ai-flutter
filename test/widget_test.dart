import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transit_app/main.dart';

void main() {
  testWidgets('Stitch Transit App boots up with Home Search and navigates to Profile',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const StitchTransitApp());
    await tester.pump();

    // Home screen verification
    expect(find.text('Transit AI'), findsOneWidget);
    expect(find.text('Search your Route'), findsOneWidget);
    expect(find.text('Book Instant Ticket (₹9.00)'), findsOneWidget);

    // Profile button tap
    final profileBtn = find.byTooltip('Account & Profile');
    expect(profileBtn, findsOneWidget);
    await tester.tap(profileBtn);
    await tester.pump();

    // Auth screen verification
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Log In & Open Wallet'), findsOneWidget);
  });
}

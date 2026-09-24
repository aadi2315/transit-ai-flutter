import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transit_app/screens/stitch_passes_screen.dart';
import 'package:transit_app/screens/stitch_payment_qr_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Passes vs Wallet Separation & Pass Discount Tests', () {
    testWidgets(
        'Passes page: Paying for pass creates active pass card on Passes page without opening ticket directly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      bool navigatedToWallet = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StitchPassesScreen(
            onNavigateToHome: () {},
            onNavigateToRouteDetails: () {},
            onNavigateToAskRoute: () {},
            onNavigateToWallet: () {
              navigatedToWallet = true;
            },
            onNavigateToProfile: () {},
            isDarkMode: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find pay button for initial pass (BRTS Monthly Corridor Pass ₹750)
      final payBtn = find.text('Pay ₹750 via UPI & Activate Pass');
      expect(payBtn, findsOneWidget);

      // Tap pay button
      await tester.ensureVisible(payBtn);
      await tester.tap(payBtn);
      await tester.pumpAndSettle();

      // Ensure it did NOT navigate to wallet directly
      expect(navigatedToWallet, isFalse);

      // Verify the Active Pass card is rendered directly on the Passes page
      expect(find.text('ACTIVE PASS'), findsOneWidget);
      expect(find.text('Ahmedabad Janmarg BRTS'), findsOneWidget);
      expect(find.text('Monthly Corridor Pass'), findsOneWidget);
      expect(find.text('DIGITAL PASS ID'), findsOneWidget);
      expect(find.text('Book Discounted Ticket in Wallet'), findsOneWidget);
    });

    testWidgets(
        'Wallet page: When active pass exists, applies 100% discount and issues ticket with pass waiver',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Seed an active pass into SharedPreferences
      SharedPreferences.setMockInitialValues({
        'transit_ai_active_pass_v2': jsonEncode({
          'pass_number': 'PASS-BRTS-998877',
          'pass_title': 'Monthly Corridor Pass',
          'operator': 'BRTS',
          'category': 'Commuter',
          'duration': '30 Days',
          'cost': 750,
          'status': 'active',
          'valid_until': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        }),
      });

      await tester.pumpWidget(
        MaterialApp(
          home: StitchPaymentQrScreen(
            onNavigateToHome: () {},
            onNavigateToRouteDetails: () {},
            onNavigateToAskRoute: () {},
            onNavigateToPasses: () {},
            onNavigateToProfile: () {},
            isDarkMode: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Active Pass Banner is displayed in Fare Checkout
      expect(find.text('BRTS PASS APPLIED'), findsOneWidget);
      expect(find.text('100% FARE WAIVER'), findsOneWidget);
      expect(find.text('FREE WITH PASS'), findsOneWidget);
      expect(find.text('INR ₹0.00'), findsOneWidget);

      // Verify pass issue CTA
      final issueWithPassBtn =
          find.text('Issue Ticket with Active Pass (FREE • ₹0.00)');
      expect(issueWithPassBtn, findsOneWidget);

      // Tap Issue Ticket with Active Pass
      await tester.tap(issueWithPassBtn);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      // Verify it transitions to ticket view with PASS HOLDER and ₹0.00
      expect(find.text('PRAVHA Dynamic Pass'), findsOneWidget);
      expect(find.text('CONFIRMED'), findsOneWidget);
      expect(find.text('PASS HOLDER'), findsOneWidget);
      expect(find.text('Covered by Pass • ₹0.00'), findsOneWidget);
    });
  });
}

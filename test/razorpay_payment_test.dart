import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transit_app/config/razorpay_config.dart';
import 'package:transit_app/services/razorpay_service.dart';
import 'package:transit_app/screens/stitch_payment_qr_screen.dart';

void main() {
  group('Razorpay Configuration & Service Tests', () {
    test('RazorpayConfig has the user test credentials', () {
      expect(RazorpayConfig.keyId, equals('YOUR_RAZORPAY_KEY_ID'));
      expect(RazorpayConfig.keySecret, equals('YOUR_RAZORPAY_KEY_SECRET'));
      expect(RazorpayConfig.merchantName, equals('Transit AI'));
      expect(RazorpayConfig.currency, equals('INR'));
    });

    test(
        'RazorpayService initializes, handles desktop fallback, and disposes safely',
        () {
      final service = RazorpayService();
      bool successCalled = false;
      bool errorCalled = false;

      service.initialize(
        onSuccess: (response) {
          successCalled = true;
        },
        onError: (error) {
          errorCalled = true;
        },
      );

      expect(service.isInitialized, isTrue);

      bool fallbackInvoked = false;
      service.openPayment(
        amount: 9,
        keyId: RazorpayConfig.keyId,
        description: 'Test Fare Booking',
        onDesktopFallbackSimulateSuccess: () {
          fallbackInvoked = true;
        },
      );

      expect(fallbackInvoked, isTrue);
      expect(successCalled, isFalse);
      expect(errorCalled, isFalse);

      service.dispose();
      expect(service.isInitialized, isFalse);
    });
  });

  group('Stitch Payment & Scanner Screen Widget Tests', () {
    testWidgets('Renders Razorpay badge, Pay CTA, and Pay by Scanner button',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: StitchPaymentQrScreen(
            onNavigateToHome: () {},
            onNavigateToRouteDetails: () {},
            onNavigateToAskRoute: () {},
            onNavigateToPasses: () {},
            onNavigateToProfile: () {},
            onToggleTheme: () {},
            isDarkMode: true,
          ),
        ),
      );
      await tester.pump();

      // Verify Razorpay Test Mode indicator
      expect(find.text('Razorpay Test Mode'), findsOneWidget);
      expect(find.text('YOUR_RAZORPAY_KEY_ID'), findsOneWidget);

      // Verify Pay button
      expect(find.text('Pay ₹9.00 via Google Pay'), findsOneWidget);

      // Verify Pay with Scanner button
      final scannerBtn = find.textContaining('Pay with Scanner');
      expect(scannerBtn, findsOneWidget);

      await tester.ensureVisible(scannerBtn);
      await tester.pump();
      await tester.tap(scannerBtn);
      // Wait for modal transition without timing out on infinite animation
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      // Verify Scanner modal elements
      expect(find.text('Scan & Pay Fare'), findsOneWidget);
      expect(find.text('Scan Terminal QR'), findsOneWidget);
      expect(find.text('Dynamic UPI QR'), findsOneWidget);
      expect(
        find.textContaining('TERMINAL DETECTED'),
        findsOneWidget,
      );
      expect(
        find.text('Pay ₹9.00 with Razorpay Gateway'),
        findsOneWidget,
      );

      // Switch to Dynamic UPI QR tab
      await tester.tap(find.text('Dynamic UPI QR'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('HOLD SCREEN AGAINST TERMINAL SCANNER'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Expires in'),
        findsOneWidget,
      );
      expect(
        find.text('Pay ₹9.00 Online via Razorpay'),
        findsOneWidget,
      );

      // Switch back to Scan Terminal QR tab
      await tester.tap(find.text('Scan Terminal QR'));
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Simulate Instant Terminal QR Clearance (Test Bypass)
      final bypassBtn =
          find.text('Simulate Instant Terminal QR Clearance (Test Bypass)');
      await tester.ensureVisible(bypassBtn);
      await tester.pump();
      await tester.tap(bypassBtn);

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      // Sheet should dismiss and transition to Dynamic QR Ticket
      expect(find.text('Dynamic QR Pass'), findsOneWidget);
      expect(find.text('CONFIRMED'), findsOneWidget);
      expect(find.text('Ahmedabad BRTS'), findsOneWidget);
      expect(find.text('₹9.00 Paid'), findsOneWidget);
    });

    testWidgets(
        'Unpaid ticket tab shows locked state; only reveals ticket QR after payment',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: StitchPaymentQrScreen(
            onNavigateToHome: () {},
            onNavigateToRouteDetails: () {},
            onNavigateToAskRoute: () {},
            onNavigateToPasses: () {},
            onNavigateToProfile: () {},
            onToggleTheme: () {},
            isDarkMode: true,
          ),
        ),
      );
      await tester.pump();

      // Tap on Dynamic QR Ticket tab before paying
      await tester.tap(find.text('Dynamic QR Ticket'));
      await tester.pump();

      // Verify locked / unpaid state
      expect(find.text('No Active Ticket Yet'), findsOneWidget);
      expect(find.text('PAYMENT REQUIRED • NO ACTIVE TICKET'), findsOneWidget);
      expect(find.text('Proceed to Payment (₹9.00)'), findsOneWidget);
      expect(find.text('CONFIRMED'), findsNothing);

      // Tap Proceed to Payment button
      await tester.tap(find.text('Proceed to Payment (₹9.00)'));
      await tester.pump();

      // Back on payment view
      expect(find.text('Pay via UPI QR Code'), findsOneWidget);

      // Tap Simulate UPI QR Payment
      final simQrBtn = find.textContaining('Confirm / Simulate UPI QR Payment');
      await tester.ensureVisible(simQrBtn);
      await tester.pump();
      await tester.tap(simQrBtn);
      await tester.pump();

      // Now Ticket QR is unlocked!
      expect(find.text('CONFIRMED'), findsOneWidget);
      expect(find.text('Ahmedabad BRTS'), findsOneWidget);
      expect(find.text('₹9.00 Paid'), findsOneWidget);
      expect(find.text('Book Another Journey / New Ticket'), findsOneWidget);

      // Tap Book Another Journey / New Ticket to reset
      await tester.tap(find.text('Book Another Journey / New Ticket'));
      await tester.pump();

      // Should be back to payment view and reset
      expect(find.text('Fare Checkout'), findsOneWidget);
    });
  });
}

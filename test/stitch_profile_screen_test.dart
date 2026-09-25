import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transit_app/main.dart';
import 'package:transit_app/services/supabase_service.dart';
import 'package:transit_app/screens/stitch_profile_screen.dart';
import 'package:transit_app/screens/stitch_auth_screen.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    SupabaseService.instance.currentUserProfile = null;
  });

  tearDown(() {
    SupabaseService.instance.currentUserProfile = null;
  });

  testWidgets(
      'Profile icon opens Login when not logged in, and opens Profile page after login or signup',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 1. App boots up without active session
    await tester.pumpWidget(const StitchTransitApp(enableSplash: false));
    await tester.pump();

    // Verify on Home screen
    expect(find.text('PRAVHA'), findsOneWidget);

    // 2. Click on Profile Icon before login
    final profileBtn = find.byTooltip('Sign In / Profile');
    expect(profileBtn, findsOneWidget);
    await tester.tap(profileBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Since not logged in, Login / Auth screen is open
    expect(find.byType(StitchAuthScreen), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);

    // 3. Perform Login
    // Tap "Demo Auto-fill" button to fill credentials
    final demoBtn = find.text('Demo Auto-fill');
    expect(demoBtn, findsOneWidget);
    await tester.tap(demoBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Tap "Sign In" button
    final signInBtn = find.text('Sign In to PRAVHA');
    expect(signInBtn, findsOneWidget);
    await tester.tap(signInBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 4. Now, the new Commuter Profile page is open!
    expect(find.byType(StitchProfileScreen), findsOneWidget);
    expect(find.text('PRAVHA PROFILE'), findsOneWidget);
    expect(find.text('Aarav Patel'), findsOneWidget);
    expect(find.text('COMMUTER TRANSIT ID'), findsOneWidget);
    expect(find.text('COMMUTER STATS'), findsOneWidget);
    expect(find.text('SMART TRANSIT PASS'), findsOneWidget);

    // 5. Navigate back to Home screen using top Back button
    final backBtn = find.byTooltip('Back');
    expect(backBtn, findsOneWidget);
    await tester.tap(backBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify we are back on Home screen
    expect(find.text('Search your Route'), findsOneWidget);

    // 6. NOW: Click on Profile Icon while logged in!
    // It should open the Profile page directly!
    await tester.tap(find.byTooltip('Sign In / Profile'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(StitchProfileScreen), findsOneWidget);
    expect(find.text('PRAVHA PROFILE'), findsOneWidget);
    expect(find.text('Aarav Patel'), findsOneWidget);

    // 7. Test "Switch Account" connection to Login page
    final switchBtn = find.text('Switch');
    expect(switchBtn, findsOneWidget);
    await tester.tap(switchBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Auth screen opens with connected profile banner
    expect(find.byType(StitchAuthScreen), findsOneWidget);
    expect(find.text('Tap to view your Commuter Profile'), findsOneWidget);

    // Tap the banner to return to Profile
    await tester.tap(find.text('Tap to view your Commuter Profile'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(StitchProfileScreen), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transit_app/main.dart';
import 'package:transit_app/config/supabase_config.dart';
import 'package:transit_app/services/supabase_service.dart';

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

    // Profile button tap (links to login)
    final profileBtn = find.byTooltip('Sign In / Profile');
    expect(profileBtn, findsOneWidget);
    await tester.tap(profileBtn);
    await tester.pump();

    // Auth screen verification
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign In to Transit AI'), findsOneWidget);

    // Switch to Sign Up tab
    final signupTab = find.text('Sign Up');
    expect(signupTab, findsOneWidget);
    await tester.tap(signupTab);
    await tester.pump();

    // Verify local origin / where you're from field
    expect(find.text("WHERE YOU'RE FROM (LOCALITY / CITY)"), findsOneWidget);
    expect(find.text('Use GPS'), findsOneWidget);
    expect(find.text('SG Highway'), findsOneWidget);

    // Tap SG Highway chip
    await tester.tap(find.text('SG Highway'));
    await tester.pump();

    // Verify field gets populated
    expect(find.text('SG Highway, Ahmedabad'), findsOneWidget);
  });

  testWidgets('Stitch Transit App navigates to Ask Route page and tests like/dislike reactions',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const StitchTransitApp());
    await tester.pump();

    // Tap ASK tab on bottom dock
    final askTab = find.text('ASK');
    expect(askTab, findsOneWidget);
    await tester.tap(askTab);
    await tester.pump();

    // Verify Ask Route screen elements
    expect(find.text('Ask Locals & Route Q&A'), findsOneWidget);
    expect(find.text('Ahmedabad Hub'), findsOneWidget);
    expect(find.text('ASK COMMUTERS FOR ROUTE ADVICE'), findsOneWidget);

    // Verify answers and like/dislike buttons exist
    expect(find.text('👍'), findsWidgets);
    expect(find.text('👎'), findsWidgets);
    expect(find.text('24'), findsOneWidget); // Initial likes for first answer

    // Scroll until first like button is visible and tap it
    final firstLike = find.text('👍').first;
    await tester.ensureVisible(firstLike);
    await tester.pump();
    await tester.tap(firstLike);
    await tester.pump();

    // Count increments to 25
    expect(find.text('25'), findsOneWidget);

    // Tap dislike on same answer
    final firstDislike = find.text('👎').first;
    await tester.ensureVisible(firstDislike);
    await tester.pump();
    await tester.tap(firstDislike);
    await tester.pump();

    // Like decrements back to 24, dislike increments to 2 (from 1)
    expect(find.text('24'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  test('SupabaseConfig holds user project credentials and SupabaseService registers locality', () async {
    // Verify user credentials in config
    expect(SupabaseConfig.supabaseUrl, 'https://your-project-id.supabase.co');
    expect(SupabaseConfig.supabaseAnonKey, 'your_supabase_anon_public_key_here');
    expect(SupabaseConfig.isConfigured, isTrue);

    // Test profile registration with locality
    final res = await SupabaseService.instance.registerUserProfile(
      fullName: 'Aarav Patel',
      phone: '98790 44120',
      locality: 'SG Highway, Ahmedabad',
    );

    expect(res['success'], isTrue);
    expect(SupabaseService.instance.currentUserProfile?['full_name'], 'Aarav Patel');
    expect(SupabaseService.instance.currentUserProfile?['locality'], 'SG Highway, Ahmedabad');
  });
}

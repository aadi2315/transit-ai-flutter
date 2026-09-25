import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transit_app/main.dart';
import 'package:transit_app/services/supabase_service.dart';

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
      'Creator can post an asking route inquiry, and then edit or delete it',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const StitchTransitApp(enableSplash: false));
    await tester.pump();

    // 1. Navigate to ASK tab
    final askTab = find.text('ASK');
    expect(askTab, findsOneWidget);
    await tester.tap(askTab);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Ask Route screen loaded
    expect(find.text('Ask Locals & Route Q&A'), findsOneWidget);
    expect(find.text('ASK COMMUTERS FOR ROUTE ADVICE'), findsOneWidget);

    // Default questions are by other commuters and should NOT have 'YOU' badge
    expect(find.text('YOU'), findsNothing);

    // 2. Post a new route question as the user
    // Find text fields: Origin, Destination, Question
    final originField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'e.g. Kalupur Stn');
    final destField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'e.g. SG Hwy');
    final questionField = find.byWidgetPredicate((w) =>
        w is TextField &&
        (w.decoration?.hintText?.contains('Ask your question') ?? false));

    await tester.ensureVisible(questionField);
    await tester.pump();

    await tester.enterText(originField, 'Navrangpura');
    await tester.enterText(destField, 'Income Tax Circle');
    await tester.enterText(
        questionField, 'Is there waterlogging near Income Tax underpass?');
    await tester.pump();

    // Tap "Ask Local Commuters" broadcast button
    final askButton = find.text('ASK LOCAL COMMUTERS');
    expect(askButton, findsOneWidget);
    await tester.ensureVisible(askButton);
    await tester.tap(askButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 3. Verify user's posted question is at the top with "YOU" badge and Edit/Delete buttons
    expect(find.text('YOU'), findsOneWidget);
    expect(find.textContaining('Is there waterlogging near Income Tax underpass?'),
        findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    // 4. Test EDIT: Tap Edit button
    final editBtn = find.text('Edit').first;
    await tester.tap(editBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify Edit bottom sheet is open
    expect(find.text('Edit Route Inquiry'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);

    // Update the question text
    final editQuestionField = find.byWidgetPredicate((w) =>
        w is TextField &&
        (w.controller?.text.contains('Income Tax underpass') ?? false));
    expect(editQuestionField, findsOneWidget);
    await tester.enterText(
        editQuestionField, 'Updated: Is Route 4D running via Income Tax?');
    await tester.pump();

    // Tap "Save Changes"
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    // Verify sheet closed and updated question is shown on the card
    expect(find.text('Edit Route Inquiry'), findsNothing);
    expect(find.textContaining('Updated: Is Route 4D running via Income Tax?'),
        findsOneWidget);

    // 5. Test DELETE: Tap Delete button
    final deleteBtn = find.text('Delete').first;
    await tester.ensureVisible(deleteBtn);
    await tester.pump();
    await tester.tap(deleteBtn);
    await tester.pumpAndSettle();

    // Verify Delete confirmation dialog is open
    expect(find.text('Delete Inquiry?'), findsOneWidget);
    expect(
        find.textContaining(
            'Are you sure you want to delete this route question?'),
        findsOneWidget);

    // Tap confirm "Delete" in the dialog
    final confirmDeleteBtn = find.widgetWithText(ElevatedButton, 'Delete');
    expect(confirmDeleteBtn, findsOneWidget);
    await tester.tap(confirmDeleteBtn);
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify dialog closed and the question is removed
    expect(find.text('Delete Inquiry?'), findsNothing);
    expect(find.textContaining('Updated: Is Route 4D running via Income Tax?'), findsNothing);
    expect(find.text('YOU'), findsNothing);
  });
}

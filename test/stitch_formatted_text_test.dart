import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transit_app/widgets/stitch_formatted_text.dart';

void main() {
  testWidgets('StitchFormattedText cleans raw asterisks and parses bold and bullets',
      (WidgetTester tester) async {
    const rawMarkdown = '''
### 🚨 Incident Summary
* **Location:** SG Highway
* **Impact:** Heavy traffic jam
**Recommendation:** Take the BRTS lane.
''';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StitchFormattedText(
            text: rawMarkdown,
            baseStyle: TextStyle(fontSize: 12, color: Colors.white),
          ),
        ),
      ),
    );

    // Verify SelectableText.rich is rendered
    final richTextFinder = find.byType(SelectableText);
    expect(richTextFinder, findsOneWidget);

    final selectableText = tester.widget<SelectableText>(richTextFinder);
    final textSpan = selectableText.textSpan!;

    // Flatten span texts
    final renderedPlainText = textSpan.toPlainText();

    // Verify no raw '**' appears in rendered text
    expect(renderedPlainText.contains('**'), isFalse);

    // Verify markdown headers ('###') are stripped
    expect(renderedPlainText.contains('###'), isFalse);

    // Verify '*' bullets became '•'
    expect(renderedPlainText.contains('•'), isTrue);

    // Verify contents are intact
    expect(renderedPlainText.contains('Incident Summary'), isTrue);
    expect(renderedPlainText.contains('SG Highway'), isTrue);
    expect(renderedPlainText.contains('Take the BRTS lane.'), isTrue);
  });
}

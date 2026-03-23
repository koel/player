import 'package:app/ui/widgets/marquee_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MarqueeText', () {
    testWidgets('renders the text', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            child: MarqueeText(text: 'Hello World'),
          ),
        ),
      ));

      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('applies custom style', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            child: MarqueeText(
              text: 'Styled',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ));

      final text = tester.widget<Text>(find.text('Styled'));
      expect(text.style?.fontSize, 24);
      expect(text.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('does not scroll when text fits', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: MarqueeText(text: 'Short'),
          ),
        ),
      ));

      await tester.pumpAndSettle();
      expect(find.text('Short'), findsOneWidget);
    });

    testWidgets('uses SingleChildScrollView internally', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 50,
            child: MarqueeText(
              text: 'A very long text that should overflow the container',
              pauseDuration: Duration.zero,
              scrollDuration: Duration(milliseconds: 50),
            ),
          ),
        ),
      ));

      expect(find.byType(SingleChildScrollView), findsOneWidget);

      // Drain animation timers
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });
}

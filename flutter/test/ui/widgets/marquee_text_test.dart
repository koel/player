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

    testWidgets('short text has no fade effect', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: MarqueeText(text: 'Short'),
          ),
        ),
      ));

      await tester.pump();
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(ShaderMask), findsNothing);
    });

    testWidgets('overflowing text shows fade effect', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 50,
            child: MarqueeText(
              text: 'This is a very long text that will definitely overflow '
                  'the tiny 50px container and trigger the marquee',
              pauseDuration: const Duration(seconds: 10),
              scrollDuration: const Duration(seconds: 10),
            ),
          ),
        ),
      ));

      // Pump twice: once for post-frame callback, once for setState rebuild
      await tester.pump();
      await tester.pump();

      expect(find.byType(ShaderMask), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      // Replace widget tree to dispose and cancel timers
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 20));
    });

    testWidgets('passes textAlign to Text widget', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: MarqueeText(
              text: 'Centered',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ));

      await tester.pump();
      final text = tester.widget<Text>(find.text('Centered'));
      expect(text.textAlign, TextAlign.center);
    });
  });
}

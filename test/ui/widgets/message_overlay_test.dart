import 'package:app/ui/widgets/message_overlay.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../extensions/widget_tester_extension.dart';

void main() {
  Future<void> _mount(
    WidgetTester tester, {
    required MessageOverlay overlay,
  }) async {
    await tester.pumpAppWidget(overlay);
    // Allow the widget to become visible (setState in initState).
    await tester.pump();
  }

  /// Advance past the timer started in initState to avoid pending timer errors.
  Future<void> _drainTimers(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
  }

  testWidgets('renders default state', (WidgetTester tester) async {
    await _mount(tester, overlay: MessageOverlay());

    expect(find.byType(MessageOverlay), findsOneWidget);
    expect(
      find.byIcon(CupertinoIcons.check_mark_circled_solid),
      findsOneWidget,
    );

    await _drainTimers(tester);
  });

  testWidgets('renders a custom icon', (WidgetTester tester) async {
    await _mount(
      tester,
      overlay: MessageOverlay(
        icon: CupertinoIcons.heart_solid,
        iconColor: Colors.pink,
      ),
    );

    expect(find.byIcon(CupertinoIcons.heart_solid), findsOneWidget);
    await _drainTimers(tester);
  });

  testWidgets('renders a caption', (WidgetTester tester) async {
    await _mount(tester, overlay: MessageOverlay(caption: 'Done!'));

    expect(find.text('Done!'), findsOneWidget);
    await _drainTimers(tester);
  });

  testWidgets('renders a message without caption', (WidgetTester tester) async {
    await _mount(
      tester,
      overlay: MessageOverlay(message: 'Banana cake cooked.'),
    );

    expect(find.text('Banana cake cooked.'), findsOneWidget);
    await _drainTimers(tester);
  });

  testWidgets('renders full', (WidgetTester tester) async {
    await _mount(
      tester,
      overlay: MessageOverlay(
        icon: CupertinoIcons.heart_solid,
        iconColor: Colors.pink,
        caption: 'Done!',
        message: 'Banana cake cooked.',
      ),
    );

    expect(find.byIcon(CupertinoIcons.heart_solid), findsOneWidget);
    expect(find.text('Done!'), findsOneWidget);
    expect(find.text('Banana cake cooked.'), findsOneWidget);
    await _drainTimers(tester);
  });

  testWidgets('uses horizontal layout with icon on the left',
      (WidgetTester tester) async {
    await _mount(
      tester,
      overlay: MessageOverlay(caption: 'Queued'),
    );

    final row = tester.widget<Row>(find.byType(Row).first);
    expect(row.children.first, isA<Icon>());
    await _drainTimers(tester);
  });

  testWidgets('is positioned near the bottom', (WidgetTester tester) async {
    await _mount(
      tester,
      overlay: MessageOverlay(caption: 'Queued'),
    );

    final align = tester.widget<Align>(find.byType(Align));
    expect(align.alignment, Alignment.bottomCenter);
    await _drainTimers(tester);
  });
}

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
    await tester.pumpAppWidget(
      Scaffold(
        backgroundColor: Colors.black26,
        body: SafeArea(
          child: Align(
            alignment: Alignment.center,
            child: overlay,
          ),
        ),
      ),
    );
  }

  testWidgets('renders default state', (WidgetTester tester) async {
    await _mount(tester, overlay: MessageOverlay());
    await expectLater(
      find.byType(MessageOverlay),
      matchesGoldenFile('goldens/message_overlay_default.png'),
    );
  });

  testWidgets('renders a custom icon', (WidgetTester tester) async {
    await _mount(
      tester,
      overlay: MessageOverlay(
        icon: CupertinoIcons.heart_solid,
        iconColor: Colors.pink,
      ),
    );

    await expectLater(
      find.byType(MessageOverlay),
      matchesGoldenFile('goldens/message_overlay_custom_icon.png'),
    );
  });

  testWidgets('renders a caption', (WidgetTester tester) async {
    await _mount(tester, overlay: MessageOverlay(caption: 'Done!'));

    await expectLater(
      find.byType(MessageOverlay),
      matchesGoldenFile('goldens/message_overlay_caption.png'),
    );
  });

  testWidgets('renders a message without caption', (WidgetTester tester) async {
    await _mount(
      tester,
      overlay: MessageOverlay(message: 'Banana cake cooked.'),
    );

    await expectLater(
      find.byType(MessageOverlay),
      matchesGoldenFile('goldens/message_overlay_message.png'),
    );
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

    await expectLater(
      find.byType(MessageOverlay),
      matchesGoldenFile('goldens/message_overlay_full.png'),
    );
  });
}

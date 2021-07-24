import 'package:app/ui/widgets/full_width_primary_icon_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../extensions/widget_extension.dart';

void main() {
  testWidgets('renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      Flex(
        direction: Axis.vertical,
        children: <Widget>[
          FullWidthPrimaryIconButton(
            icon: CupertinoIcons.phone,
            label: 'Call Me',
          )
        ],
      ).wrapForTest(),
    );

    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.byType(Icon), findsOneWidget);
    expect(find.text('Call Me'), findsOneWidget);

    await expectLater(
      find.byType(FullWidthPrimaryIconButton),
      matchesGoldenFile(
        '../goldens/widgets/full_width_primary_icon_button.png',
      ),
    );
  });

  testWidgets('triggers callback', (WidgetTester tester) async {
    var onPressed = MockOnPress();

    await tester.pumpWidget(
      Flex(
        direction: Axis.vertical,
        children: <Widget>[
          FullWidthPrimaryIconButton(
            icon: CupertinoIcons.phone,
            label: 'Call Me',
            onPressed: onPressed,
          )
        ],
      ).wrapForTest(),
    );

    await tester.tap(find.byType(ElevatedButton));
    expect(onPressed.called, isTrue);
  });
}

class MockOnPress {
  bool called = false;
  call() => called = true;
}

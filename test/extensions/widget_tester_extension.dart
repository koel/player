import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

extension WidgetTesterExtension on WidgetTester {
  Future<void> pumpKoelWidget(
    Widget widget, {
    Size surfaceSize = const Size(800, 600),
  }) async {
    await pumpWidgetBuilder(
      widget,
      wrapper: materialAppWrapper(
        theme: ThemeData.dark(),
        platform: TargetPlatform.iOS,
      ),
    );
  }
}

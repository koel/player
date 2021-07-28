import 'package:app/ui/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

extension WidgetTesterExtension on WidgetTester {
  Future<void> pumpAppWidget(
    Widget widget, {
    Size surfaceSize = const Size(375, 812), // iPhone X
    NavigatorObserver? navigatorObserver,
    Map<String, Widget Function(BuildContext)>? routes,
  }) async {
    await pumpWidgetBuilder(
      widget,
      wrapper: (Widget widget) {
        return Builder(
          builder: (BuildContext context) {
            return MaterialApp(
              theme: themeData(context).copyWith(platform: TargetPlatform.iOS),
              navigatorObservers: [
                if (navigatorObserver != null) navigatorObserver,
              ],
              home: Material(child: widget),
              routes: routes ?? {},
            );
          },
        );
      },
      surfaceSize: surfaceSize,
    );
  }
}

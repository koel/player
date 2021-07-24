import 'package:flutter/material.dart';

extension WidgetExtension on Widget {
  /// Wrap the widget inside a MaterialApp with proper MediaQuery setup for easy
  /// testing.
  /// If the system under test involves redirections, [routes] should be
  /// provided for proper Navigator behavior and assertion.
  Widget wrapForTest({Map<String, Widget Function(BuildContext)>? routes}) {
    return MediaQuery(
      data: MediaQueryData(),
      child: Material(
        child: MaterialApp(
          home: this,
          routes: routes ?? {},
        ),
      ),
    );
  }
}

import 'package:app/utils/preferences.dart' as preferences;
import 'package:flutter/material.dart';

class GradientDecoratedContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const GradientDecoratedContainer(
      {Key? key, this.child = const SizedBox.expand(), this.padding})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = preferences.isDarkTheme;

    return Container(
      child: child,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF000000) : null,
        image: isDark ? null : const DecorationImage(
          image: AssetImage('assets/images/background.webp'),
          fit: BoxFit.cover,
          alignment: Alignment.bottomLeft,
        ),
      ),
    );
  }
}

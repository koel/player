import 'dart:io';

import 'package:app/constants/constants.dart';
import 'package:app/utils/preferences.dart' as preferences;
import 'package:flutter/material.dart';

final backgroundImageNotifier = ValueNotifier<String?>(null);
final highlightColorNotifier = ValueNotifier<Color>(AppColors.highlight);

void initBackgroundPreference() {
  backgroundImageNotifier.value = preferences.backgroundImagePath;
  final savedColor = preferences.highlightColor;
  if (savedColor != null) {
    highlightColorNotifier.value = savedColor;
  }
}

Color get highlightColor => highlightColorNotifier.value;

Color get highlightAccentColor {
  final hsl = HSLColor.fromColor(highlightColor);
  return hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor();
}

Color get headerBackgroundColor {
  final hsl = HSLColor.fromColor(highlightColor);
  return hsl.withLightness(0.08).withSaturation(0.5).toColor();
}

class GradientDecoratedContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const GradientDecoratedContainer(
      {Key? key, this.child = const SizedBox.expand(), this.padding})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: backgroundImageNotifier,
      builder: (context, customPath, _) {
        final ImageProvider image;

        if (customPath != null && File(customPath).existsSync()) {
          image = FileImage(File(customPath));
        } else {
          image = const AssetImage('assets/images/background.webp');
        }

        return Container(
          child: child,
          padding: padding,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: image,
              fit: BoxFit.cover,
              alignment: Alignment.bottomLeft,
            ),
          ),
        );
      },
    );
  }
}

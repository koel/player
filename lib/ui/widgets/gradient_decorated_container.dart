import 'dart:io';

import 'package:app/utils/preferences.dart' as preferences;
import 'package:flutter/material.dart';

final backgroundImageNotifier = ValueNotifier<String?>(null);

void initBackgroundPreference() {
  backgroundImageNotifier.value = preferences.backgroundImagePath;
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

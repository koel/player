import 'package:app/ui/placeholders/circle_placeholder.dart';
import 'package:app/ui/placeholders/gradient_placeholder.dart';
import 'package:flutter/material.dart';

class MediaInfoPanePlaceholder extends StatelessWidget {
  const MediaInfoPanePlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GradientPlaceholder(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const CirclePlaceholder(size: 48),
                const SizedBox(width: 12),
                Container(width: 124, height: 48, color: Colors.white),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ...List.generate(4, (_) => const LineOfText()).toList(),
          const LineOfText(width: 120),
          const SizedBox(height: 18),
          ...List.generate(2, (_) => const LineOfText()).toList(),
          const LineOfText(width: 180),
        ],
      ),
    );
  }
}

class LineOfText extends StatelessWidget {
  final double? width;

  const LineOfText({Key? key, this.width}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.0),
      child: Container(width: width, height: 16.0, color: Colors.white),
    );
  }
}

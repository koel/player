import 'package:app/constants/constants.dart';
import 'package:app/ui/placeholders/circle_placeholder.dart';
import 'package:flutter/material.dart';

class PlayableRowPlaceholder extends StatelessWidget {
  const PlayableRowPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.hPadding,
        vertical: 4,
      ),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      title: Container(
        width: 200,
        height: 14,
        color: Colors.white,
        margin: const EdgeInsets.only(right: 80),
      ),
      subtitle: Container(
        width: 200,
        height: 12,
        color: Colors.white.withOpacity(.5),
        margin: const EdgeInsets.only(right: 160),
      ),
      trailing: const CirclePlaceholder(size: 24),
    );
  }
}

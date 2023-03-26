import 'dart:math';

import 'package:flutter/material.dart';

class ArtistRowPlaceholder extends StatelessWidget {
  const ArtistRowPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: Border(bottom: Divider.createBorderSide(context)),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
      title: Container(
        height: 16,
        color: Colors.white,
        margin: EdgeInsets.only(right: Random().nextInt(180).toDouble()),
      ),
    );
  }
}

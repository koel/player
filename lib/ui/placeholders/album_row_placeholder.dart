import 'package:flutter/material.dart';

class AlbumRowPlaceholder extends StatelessWidget {
  const AlbumRowPlaceholder({Key? key}) : super(key: key);

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
        margin: const EdgeInsets.only(right: 80),
      ),
      subtitle: Container(
        height: 16,
        color: Colors.white,
        margin: const EdgeInsets.only(right: 140),
      ),
    );
  }
}

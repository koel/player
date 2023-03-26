import 'package:app/ui/placeholders/rounded_button_placeholder.dart';
import 'package:flutter/material.dart';

class SongRowPlaceholder extends StatelessWidget {
  const SongRowPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      shape: Border(bottom: Divider.createBorderSide(context)),
      title: Container(
        width: 200,
        height: 16,
        color: Colors.white,
        margin: const EdgeInsets.only(right: 80),
      ),
      subtitle: Container(
        width: 200,
        height: 16,
        color: Colors.white,
        margin: const EdgeInsets.only(right: 140),
      ),
      trailing: const RoundedButtonPlaceholder(size: 24),
    );
  }
}

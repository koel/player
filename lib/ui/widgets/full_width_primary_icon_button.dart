import 'package:flutter/material.dart';

class FullWidthPrimaryIconButton extends StatelessWidget {
  final dynamic icon;
  final String label;
  final void Function()? onPressed;

  const FullWidthPrimaryIconButton({
    Key? key,
    required this.icon,
    required this.label,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        child: Row(
          children: <Widget>[
            if (icon is IconData) Icon(icon, size: 20) else icon,
            Expanded(child: Text(label, textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }
}

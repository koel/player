import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FullWidthPrimaryIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const FullWidthPrimaryIconButton({
    Key? key,
    required this.icon,
    required this.label,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ConstrainedBox(
        constraints: const BoxConstraints.expand(
          width: double.infinity,
          height: 48,
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            primary: Colors.grey.shade900,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          onPressed: onPressed,
          child: Row(
            children: <Widget>[
              Icon(icon, size: 20),
              Expanded(
                child: Text(label, textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

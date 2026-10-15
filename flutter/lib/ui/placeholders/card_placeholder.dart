import 'package:flutter/material.dart';

class CardPlaceholder extends StatelessWidget {
  const CardPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12.0,
      direction: Axis.vertical,
      children: <Widget>[
        Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        Container(
          width: 96,
          height: 14,
          color: Colors.white,
        ),
        Container(
          width: 64,
          height: 12,
          color: Colors.white54,
        ),
      ],
    );
  }
}

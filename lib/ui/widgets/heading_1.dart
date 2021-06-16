import 'package:flutter/material.dart';

class Heading1 extends StatelessWidget {
  final String _text;

  const Heading1({
    Key? key,
    required String text,
  })  : _text = text,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_text, style: Theme.of(context).textTheme.headline5),
        SizedBox(height: 24),
      ],
    );
  }
}

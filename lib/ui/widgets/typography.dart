import 'package:flutter/material.dart';

class Heading5 extends StatelessWidget {
  final String text;

  const Heading5({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      child: Text(
        text,
        style: Theme.of(context).textTheme.headline5,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class LargeTitle extends StatelessWidget {
  final String text;

  const LargeTitle({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white),
    );
  }
}

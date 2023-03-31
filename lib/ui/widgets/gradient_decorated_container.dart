import 'package:flutter/material.dart';

class GradientDecoratedContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const GradientDecoratedContainer(
      {Key? key, this.child = const SizedBox.expand(), this.padding})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: child,
      padding: padding,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color.fromRGBO(10, 53, 159, 1),
            Color.fromRGBO(57, 87, 98, 1),
            Color.fromRGBO(188, 30, 13, 1),
          ],
          stops: [0.0, 0.4, 1.0],
        ),
      ),
    );
  }
}

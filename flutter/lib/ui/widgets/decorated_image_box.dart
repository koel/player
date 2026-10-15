import 'package:flutter/cupertino.dart';

class DecoratedImageBox extends StatelessWidget {
  final ImageProvider image;
  final double borderRadius;

  const DecoratedImageBox({
    Key? key,
    required this.image,
    required this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: image,
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
      ),
    );
  }
}

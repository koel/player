import 'package:flutter/cupertino.dart';

class BottomSpace extends StatelessWidget {
  final double height;

  const BottomSpace({
    Key? key,
    this.height = 160,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height);
  }
}

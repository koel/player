import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class Spinner extends StatelessWidget {
  final double size;

  const Spinner({Key? key, this.size = 32.0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SpinKitFadingCube(
      color: Colors.white,
      size: size,
    );
  }
}

class ContainerWithSpinner extends StatelessWidget {
  final double spinnerSize;

  const ContainerWithSpinner({Key? key, this.spinnerSize = 32.0})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Center(child: Spinner(size: spinnerSize)),
        ],
      ),
    );
  }
}

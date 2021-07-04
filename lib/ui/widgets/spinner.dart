import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

Widget spinner({double size = 32.0}) {
  return SpinKitFadingCube(
    color: Colors.white,
    size: size,
  );
}

Widget containerWithSpinner({double spinnerSize = 32.0}) {
  return Container(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Center(child: spinner(size: spinnerSize)),
      ],
    ),
  );
}

import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // this basically makes it so you can't instantiate this class

  static const black = const Color(0xFF181818);
  static const white = const Color(0xFFFFFFFF);
  static const red = const Color(0xFFBB0054);

  static const text = Color.fromRGBO(255, 255, 255, .9);
  static const background = AppColors.black;
  static const highlight = const Color(0xFFF80A95);
  static const highlightAccent = const Color(0xFFC20C75);

  static const staticScreenHeaderBackground = Colors.transparent;
  static const flexibleScreenHeaderBackground = Color.fromRGBO(25, 0, 64, .5);
}

import 'package:flutter/material.dart';

heading1({required String text}) {
  return Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 24),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      overflow: TextOverflow.ellipsis,
    ),
  );
}

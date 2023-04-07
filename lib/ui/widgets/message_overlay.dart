import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MessageOverlay extends StatelessWidget {
  final String? caption;
  final String? message;
  final IconData icon;
  final Color iconColor;

  const MessageOverlay({
    Key? key,
    this.caption,
    this.message,
    this.icon = CupertinoIcons.check_mark_circled_solid,
    this.iconColor = Colors.white30,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(16.0)),
        color: Color.fromRGBO(20, 20, 20, 1),
      ),
      padding: EdgeInsets.all(16.0),
      width: 256.0,
      height: 256.0,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 80.0, color: iconColor),
            if (caption != null) ...<Widget>[
              const SizedBox(height: 16.0),
              Text(
                caption!,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headline6
                    ?.copyWith(color: Colors.white60),
              ),
            ],
            if (message != null) ...<Widget>[
              const SizedBox(height: 16.0),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyText1
                    ?.copyWith(color: Colors.white60),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

void showOverlay(
  BuildContext context, {
  String? caption,
  String? message,
  IconData icon = CupertinoIcons.check_mark_circled_solid,
  Color iconColor = Colors.white30,
  Duration? timeOut = const Duration(seconds: 2),
}) {
  late OverlayEntry _entry;

  _entry = OverlayEntry(builder: (_) {
    return GestureDetector(
      onTap: () => _entry.remove(),
      child: Scaffold(
        backgroundColor: Colors.black26,
        body: SafeArea(
          child: Align(
            alignment: Alignment.center,
            child: MessageOverlay(
              caption: caption,
              message: message,
              icon: icon,
              iconColor: iconColor,
            ),
          ),
        ),
      ),
    );
  });

  if (timeOut != null) {
    Timer(timeOut, () {
      try {
        _entry.remove();
      } catch (error) {}
    });
  }

  Navigator.of(context).overlay?.insert(_entry);
}

import 'package:app/main.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RepeatModeButton extends StatefulWidget {
  const RepeatModeButton({Key? key}) : super(key: key);

  @override
  _RepeatModeButtonState createState() => _RepeatModeButtonState();
}

class _RepeatModeButtonState extends State<RepeatModeButton> {
  late AudioServiceRepeatMode _repeatMode;

  @override
  void initState() {
    super.initState();
    setState(() => _repeatMode = audioHandler.repeatMode);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      color: _repeatMode == AudioServiceRepeatMode.none
          ? Colors.white24
          : Colors.white,
      onPressed: () async {
        final repeatMode = await audioHandler.rotateRepeatMode();
        setState(() => _repeatMode = repeatMode);
      },
      icon: Icon(
        _repeatMode == AudioServiceRepeatMode.one
            ? CupertinoIcons.repeat_1
            : CupertinoIcons.repeat,
      ),
    );
  }
}

import 'dart:async';

import 'package:app/providers/audio_player_provider.dart';
import 'package:app/utils/preferences.dart' as preferences;
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoopModeButton extends StatefulWidget {
  LoopModeButton({Key? key}) : super(key: key);

  @override
  _LoopModeButtonState createState() => _LoopModeButtonState();
}

class _LoopModeButtonState extends State<LoopModeButton> {
  late LoopMode _loopMode;
  List<StreamSubscription> _subscriptions = [];
  late AudioPlayerProvider audio;

  @override
  void initState() {
    super.initState();
    audio = context.read();

    preferences.loopMode.then((value) => setState(() => _loopMode = value));

    _subscriptions.add(audio.player.loopMode.listen((loopMode) {
      setState(() => _loopMode = loopMode);
    }));
  }

  @override
  void dispose() {
    _subscriptions.forEach((sub) => sub.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      color: _loopMode == LoopMode.none
          ? Colors.white.withOpacity(.2)
          : Colors.white,
      onPressed: () async {
        late LoopMode newMode;
        if (_loopMode == LoopMode.none)
          newMode = LoopMode.playlist;
        else if (_loopMode == LoopMode.playlist)
          newMode = LoopMode.single;
        else
          newMode = LoopMode.none;
        audio.player.setLoopMode(newMode);
        await preferences.setLoopMode(newMode);
      },
      icon: Icon(
        _loopMode == LoopMode.single
            ? CupertinoIcons.repeat_1
            : CupertinoIcons.repeat,
      ),
    );
  }
}

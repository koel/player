import 'package:app/providers/audio_player_provider.dart';
import 'package:app/utils/preferences.dart' as preferences;
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoopModeButton extends StatefulWidget {
  const LoopModeButton({Key? key}) : super(key: key);

  @override
  _LoopModeButtonState createState() => _LoopModeButtonState();
}

class _LoopModeButtonState extends State<LoopModeButton> {
  LoopMode _loopMode = LoopMode.none;
  late AudioPlayerProvider audio;

  @override
  void initState() {
    super.initState();
    audio = context.read();

    setState(() => _loopMode = preferences.loopMode);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      color: _loopMode == LoopMode.none ? Colors.white24 : Colors.white,
      onPressed: () async {
        late LoopMode newMode;

        if (_loopMode == LoopMode.none) {
          newMode = LoopMode.playlist;
        } else if (_loopMode == LoopMode.playlist) {
          newMode = LoopMode.single;
        } else {
          newMode = LoopMode.none;
        }

        setState(() => _loopMode = newMode);
        preferences.loopMode = newMode;
        audio.player.setLoopMode(newMode);
      },
      icon: Icon(
        _loopMode == LoopMode.single
            ? CupertinoIcons.repeat_1
            : CupertinoIcons.repeat,
      ),
    );
  }
}

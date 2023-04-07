import 'package:app/providers/audio_provider.dart';
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
  late AudioProvider audio;

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

        if (newMode == LoopMode.single &&
            audio.player.playlist?.numberOfItems == 1) {
          /// Assets Audio Player has a weird bug (?) where setting Single loop
          /// mode when there's only one song in the playlist would simply
          /// crash the app.
          /// Since the previous mode is Playlist, we can safely skip setting
          /// Single mode here, as it would have the same effect anyway.
        } else {
          audio.player.setLoopMode(newMode);
        }
      },
      icon: Icon(
        _loopMode == LoopMode.single
            ? CupertinoIcons.repeat_1
            : CupertinoIcons.repeat,
      ),
    );
  }
}

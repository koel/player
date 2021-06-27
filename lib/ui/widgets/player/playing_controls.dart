import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

class PlayingControls extends StatelessWidget {
  final bool isPlaying;
  final LoopMode? loopMode;
  final bool isPlaylist;
  final Function()? onPrevious;
  final Function() onPlay;
  final Function()? onNext;
  final Function()? toggleLoop;
  final Function()? onStop;

  PlayingControls({
    required this.isPlaying,
    this.isPlaylist = false,
    this.loopMode,
    this.toggleLoop,
    this.onPrevious,
    required this.onPlay,
    this.onNext,
    this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        IconButton(
          onPressed: onPlay,
          icon: Icon(
            isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
            size: 24,
          ),
        ),
        SizedBox(
          width: 4,
        ),
        IconButton(
          onPressed: onNext,
          icon: Icon(
            CupertinoIcons.forward_fill,
            size: 24,
          ),
        ),
      ],
    );
  }
}

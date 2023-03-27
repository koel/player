import 'package:app/main.dart';
import 'package:app/mixins/stream_subscriber.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

class AudioControls extends StatelessWidget {
  const AudioControls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          onPressed: audioHandler.maybeSkipToPrevious,
          icon: const Icon(CupertinoIcons.backward_fill),
          iconSize: 48,
        ),
        const PlayPauseButton(),
        IconButton(
          onPressed: audioHandler.skipToNext,
          icon: const Icon(CupertinoIcons.forward_fill),
          iconSize: 48,
        ),
      ],
    );
  }
}

class PlayPauseButton extends StatefulWidget {
  const PlayPauseButton({Key? key}) : super(key: key);

  @override
  _PlayPauseButtonState createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<PlayPauseButton>
    with StreamSubscriber {
  PlaybackState? _state;

  @override
  void initState() {
    super.initState();
    subscribe(audioHandler.playbackState.listen((PlaybackState value) {
      setState(() => _state = value);
    }));
  }

  @override
  void dispose() {
    unsubscribeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_state == null) return const SizedBox.shrink();

    return IconButton(
      onPressed: audioHandler.playOrPause,
      icon: _state!.playing
          ? const Icon(CupertinoIcons.pause_solid)
          : const Icon(CupertinoIcons.play_fill),
      iconSize: 64,
    );
  }
}

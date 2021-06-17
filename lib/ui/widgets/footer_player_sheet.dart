import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

class FooterPlayerSheet extends StatefulWidget {
  @override
  _FooterPlayerSheetState createState() => _FooterPlayerSheetState();
}

class _FooterPlayerSheetState extends State<FooterPlayerSheet> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        StreamBuilder<MediaItem?>(
          stream: AudioService.currentMediaItemStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return SizedBox();
            }
            return Row(children: [Text(snapshot.data!.title)]);
          },
        ),
        StreamBuilder<bool>(
          stream: AudioService.playbackStateStream
              .map((state) => state.playing)
              .distinct(),
          builder: (context, snapshot) {
            final playing = snapshot.data ?? false;
            return playing ? pauseButton() : playButton();
          },
        ),
      ],
    );
  }

  IconButton playButton() => IconButton(
        icon: Icon(Icons.play_arrow),
        iconSize: 48.0,
        onPressed: AudioService.play,
      );

  IconButton pauseButton() => IconButton(
        icon: Icon(Icons.pause),
        iconSize: 48.0,
        onPressed: AudioService.pause,
      );
}

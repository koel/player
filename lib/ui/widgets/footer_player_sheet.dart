import 'package:app/models/song.dart';
import 'package:app/providers/song_provider.dart';
import 'package:app/ui/widgets/song_thumbnail.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FooterPlayerSheet extends StatefulWidget {
  @override
  _FooterPlayerSheetState createState() => _FooterPlayerSheetState();
}

class _FooterPlayerSheetState extends State<FooterPlayerSheet> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem?>(
      stream: AudioService.currentMediaItemStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox();
        }

        SongProvider songProvider = Provider.of<SongProvider>(context);
        Song song = songProvider.byId(snapshot.data!.extras!['songId']);

        return Container(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SongThumbnail(song: song),
              Text(snapshot.data!.title),
              StreamBuilder<bool>(
                stream: AudioService.playbackStateStream
                    .map((state) => state.playing)
                    .distinct(),
                builder: (context, snapshot) {
                  final playing = snapshot.data ?? false;
                  return playing ? pauseButton() : playButton();
                },
              ),
              nextButton(),
            ],
          ),
        );
      },
    );
  }

  IconButton playButton() => IconButton(
        icon: Icon(Icons.play_arrow),
        iconSize: 48.0,
        onPressed: AudioService.play,
      );

  IconButton pauseButton() => IconButton(
        icon: Icon(Icons.pause),
        iconSize: 32.0,
        onPressed: AudioService.pause,
      );

  IconButton nextButton() => IconButton(
        icon: Icon(Icons.skip_next),
        iconSize: 32.0,
        onPressed: AudioService.skipToNext,
      );
}

import 'package:app/models/song.dart';
import 'package:app/providers/audio_player_provider.dart';
import 'package:app/ui/widgets/song_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SongCard extends StatefulWidget {
  final Song song;

  SongCard({Key? key, required this.song}) : super(key: key);

  @override
  _SongCardState createState() => _SongCardState();
}

class _SongCardState extends State<SongCard> {
  double _opacity = 1;

  @override
  Widget build(BuildContext context) {
    AudioPlayerProvider audio = context.watch<AudioPlayerProvider>();

    return GestureDetector(
      onTapDown: (_) => setState(() => _opacity = .7),
      onTapCancel: () => setState(() => _opacity = 1),
      onTap: () async {
        setState(() => _opacity = 1);
        await audio.play(song: widget.song);
      },
      child: Opacity(
        opacity: _opacity,
        child: Column(
          children: [
            SongThumbnail(song: widget.song, size: ThumbnailSize.large),
            SizedBox(height: 12),
            SizedBox(
              width: 144,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.song.title,
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    widget.song.artist.name,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.caption?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

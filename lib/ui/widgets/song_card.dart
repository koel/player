import 'package:app/models/song.dart';
import 'package:app/providers/audio_provider.dart';
import 'package:app/ui/widgets/song_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SongCard extends StatefulWidget {
  final Song song;

  const SongCard({Key? key, required this.song}) : super(key: key);

  @override
  _SongCardState createState() => _SongCardState();
}

class _SongCardState extends State<SongCard> {
  double _opacity = 1.0;
  double _cardWidth = 144.0;

  @override
  Widget build(BuildContext context) {
    AudioProvider audio = context.watch();

    return GestureDetector(
      onTapDown: (_) => setState(() => _opacity = 0.7),
      onTapCancel: () => setState(() => _opacity = 1.0),
      onTap: () async {
        setState(() => _opacity = 1.0);
        await audio.play(song: widget.song);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(microseconds: 100),
        opacity: _opacity,
        child: Column(
          children: <Widget>[
            SongThumbnail(song: widget.song, size: ThumbnailSize.md),
            const SizedBox(height: 12),
            SizedBox(
              width: _cardWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.song.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.song.artist.name,
                    style: const TextStyle(color: Colors.white54),
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

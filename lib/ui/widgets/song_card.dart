import 'package:app/main.dart';
import 'package:app/models/models.dart';
import 'package:app/router.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SongCard extends StatefulWidget {
  final Song song;
  final AppRouter router;

  const SongCard({
    Key? key,
    required this.song,
    this.router = const AppRouter(),
  }) : super(key: key);

  @override
  _SongCardState createState() => _SongCardState();
}

class _SongCardState extends State<SongCard> {
  var _opacity = 1.0;
  final _cardWidth = 144.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _opacity = 0.7),
      onTapCancel: () => setState(() => _opacity = 1.0),
      onTap: () async {
        setState(() => _opacity = 1.0);
        await audioHandler.queueAndPlay(widget.song);
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        widget.router.showActionSheet(context, song: widget.song);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(microseconds: 100),
        opacity: _opacity,
        child: Column(
          children: <Widget>[
            SongThumbnail.md(song: widget.song),
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
                  const SizedBox(height: 6),
                  Text(
                    widget.song.artistName,
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

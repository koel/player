import 'package:app/main.dart';
import 'package:app/models/models.dart';
import 'package:app/router.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SongCard extends StatefulWidget {
  final Playable playable;
  final AppRouter router;

  const SongCard({
    Key? key,
    required this.playable,
    this.router = const AppRouter(),
  }) : super(key: key);

  /// Convenience constructor for backward compatibility.
  SongCard.fromSong({Key? key, required Song song, AppRouter router = const AppRouter()})
      : this(key: key, playable: song, router: router);

  @override
  _SongCardState createState() => _SongCardState();
}

class _SongCardState extends State<SongCard> {
  var _opacity = 1.0;
  final _cardWidth = 144.0;

  String get _subtitle {
    final playable = widget.playable;
    if (playable is Song) return playable.artistName;
    if (playable is Episode) return playable.podcastTitle;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _opacity = 0.7),
      onTapCancel: () => setState(() => _opacity = 1.0),
      onTap: () async {
        setState(() => _opacity = 1.0);
        await audioHandler.queueAndPlay(widget.playable);
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        widget.router
            .showPlayableActionSheet(context, playable: widget.playable);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(microseconds: 100),
        opacity: _opacity,
        child: Column(
          children: <Widget>[
            PlayableThumbnail.md(playable: widget.playable),
            const SizedBox(height: 12),
            SizedBox(
              width: _cardWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.playable.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _subtitle,
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

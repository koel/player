import 'package:app/models/models.dart';
import 'package:app/router.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/material.dart';

class PodcastCard extends StatefulWidget {
  final Podcast podcast;
  final AppRouter router;

  PodcastCard({
    Key? key,
    required this.podcast,
    this.router = const AppRouter(),
  }) : super(key: key);

  @override
  _PodcastCardState createState() => _PodcastCardState();
}

class _PodcastCardState extends State<PodcastCard> {
  var _opacity = 1.0;
  final _cardWidth = 144.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _opacity = 0.4),
      onTapUp: (_) => setState(() => _opacity = 1.0),
      onTapCancel: () => setState(() => _opacity = 1.0),
      onTap: () => widget.router.gotoPodcastDetailsScreen(
        context,
        podcastId: widget.podcast.id,
      ),
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _opacity,
        child: Column(
          children: <Widget>[
            AlbumArtistThumbnail.md(entity: widget.podcast, asHero: true),
            const SizedBox(height: 12),
            SizedBox(
              width: _cardWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.podcast.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.podcast.author,
                    style: const TextStyle(color: Colors.white54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

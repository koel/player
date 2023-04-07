import 'package:app/models/album.dart';
import 'package:app/router.dart';
import 'package:app/ui/widgets/album_thumbnail.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AlbumCard extends StatefulWidget {
  final Album album;
  final AppRouter router;

  AlbumCard({
    Key? key,
    required this.album,
    this.router = const AppRouter(),
  }) : super(key: key);

  @override
  _AlbumCardState createState() => _AlbumCardState();
}

class _AlbumCardState extends State<AlbumCard> {
  double _opacity = 1.0;
  double _cardWidth = 144.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _opacity = 0.4),
      onTapUp: (_) => setState(() => _opacity = 1.0),
      onTapCancel: () => setState(() => _opacity = 1.0),
      onTap: () => widget.router.gotoAlbumDetailsScreen(
        context,
        album: widget.album,
      ),
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _opacity,
        child: Column(
          children: <Widget>[
            AlbumThumbnail(
              album: widget.album,
              size: ThumbnailSize.md,
              asHero: true,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: _cardWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.album.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.album.artist.name,
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

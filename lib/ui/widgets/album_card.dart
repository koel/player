import 'package:app/models/album.dart';
import 'package:app/ui/screens/album_details.dart';
import 'package:app/ui/widgets/album_thumbnail.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AlbumCard extends StatefulWidget {
  final Album album;

  AlbumCard({Key? key, required this.album}) : super(key: key);

  @override
  _AlbumCardState createState() => _AlbumCardState();
}

class _AlbumCardState extends State<AlbumCard> {
  double opacity = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => opacity = .4),
      onTapUp: (_) => setState(() => opacity = 1),
      onTapCancel: () => setState(() => opacity = 1),
      onTap: () => gotoDetailsScreen(context, album: widget.album),
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 100),
        opacity: opacity,
        child: Column(
          children: <Widget>[
            AlbumThumbnail(
              album: widget.album,
              size: ThumbnailSize.md,
              asHero: true,
            ),
            SizedBox(height: 8),
            SizedBox(
              width: 144,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.album.name,
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    widget.album.artist.name,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.caption?.color,
                    ),
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

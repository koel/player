import 'package:app/models/album.dart';
import 'package:app/ui/screens/album_details.dart';
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
      onTap: () => _gotoAlbumDetailsScreen(context, widget.album),
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 100),
        opacity: opacity,
        child: Column(
          children: <Widget>[
            SizedBox(
              width: 144,
              height: 144,
              child: Hero(
                tag: "album-hero-${widget.album.id}",
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: widget.album.image,
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
              ),
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

  void _gotoAlbumDetailsScreen(BuildContext context, Album album) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (BuildContext context) => AlbumDetailsScreen(album: album),
    ));
  }
}

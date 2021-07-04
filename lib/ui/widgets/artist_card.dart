import 'package:app/models/artist.dart';
import 'package:app/ui/screens/artist_details.dart';
import 'package:app/ui/widgets/artist_thumbnail.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ArtistCard extends StatefulWidget {
  final Artist artist;

  ArtistCard({Key? key, required this.artist}) : super(key: key);

  @override
  _ArtistCardState createState() => _ArtistCardState();
}

class _ArtistCardState extends State<ArtistCard> {
  double opacity = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => opacity = .4),
      onTapUp: (_) => setState(() => opacity = 1),
      onTapCancel: () => setState(() => opacity = 1),
      onTap: () => gotoDetailsScreen(context, artist: widget.artist),
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 100),
        opacity: opacity,
        child: Column(
          children: <Widget>[
            ArtistThumbnail(
              artist: widget.artist,
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
                    widget.artist.name,
                    style: TextStyle(fontWeight: FontWeight.bold),
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

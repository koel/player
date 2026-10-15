import 'package:app/models/models.dart';
import 'package:app/providers/artist_provider.dart';
import 'package:app/router.dart';
import 'package:app/ui/screens/artist_action_sheet.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ArtistCard extends StatefulWidget {
  final Artist artist;
  final AppRouter router;

  /// Whether the thumbnail animates to the details screen as a Hero. Set to
  /// false when the same artist may appear more than once in a route (e.g.
  /// across Home blocks), so hero tags stay unique.
  final bool asHero;

  ArtistCard({
    Key? key,
    required this.artist,
    this.router = const AppRouter(),
    this.asHero = true,
  }) : super(key: key);

  @override
  _ArtistCardState createState() => _ArtistCardState();
}

class _ArtistCardState extends State<ArtistCard> {
  var _opacity = 1.0;
  final _cardWidth = 144.0;

  @override
  Widget build(BuildContext context) {
    return Consumer<ArtistProvider>(
      builder: (_, __, ___) => GestureDetector(
        onTapDown: (_) => setState(() => _opacity = 0.4),
        onTapUp: (_) => setState(() => _opacity = 1.0),
        onTapCancel: () => setState(() => _opacity = 1.0),
        onTap: () => widget.router.gotoArtistDetailsScreen(
          context,
          artistId: widget.artist.id,
        ),
        onLongPress: () =>
            showArtistActionSheet(context, artist: widget.artist),
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: _opacity,
          child: Column(
            children: <Widget>[
              AlbumArtistThumbnail.md(
                  entity: widget.artist, asHero: widget.asHero),
              const SizedBox(height: 12),
              SizedBox(
                width: _cardWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      widget.artist.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

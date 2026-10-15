import 'package:app/models/models.dart';
import 'package:app/providers/album_provider.dart';
import 'package:app/router.dart';
import 'package:app/ui/screens/album_action_sheet.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AlbumCard extends StatefulWidget {
  final Album album;
  final AppRouter router;

  /// Whether the thumbnail animates to the details screen as a Hero. Set to
  /// false when the same album may appear more than once in a route (e.g.
  /// across Home blocks), so hero tags stay unique.
  final bool asHero;

  AlbumCard({
    Key? key,
    required this.album,
    this.router = const AppRouter(),
    this.asHero = true,
  }) : super(key: key);

  @override
  _AlbumCardState createState() => _AlbumCardState();
}

class _AlbumCardState extends State<AlbumCard> {
  var _opacity = 1.0;
  final _cardWidth = 144.0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AlbumProvider>(
      builder: (_, __, ___) => GestureDetector(
        onTapDown: (_) => setState(() => _opacity = 0.4),
        onTapUp: (_) => setState(() => _opacity = 1.0),
        onTapCancel: () => setState(() => _opacity = 1.0),
        onTap: () => widget.router.gotoAlbumDetailsScreen(
          context,
          albumId: widget.album.id,
        ),
        onLongPress: () => showAlbumActionSheet(context, album: widget.album),
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: _opacity,
          child: Column(
            children: <Widget>[
              AlbumArtistThumbnail.md(
                  entity: widget.album, asHero: widget.asHero),
              const SizedBox(height: 12),
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
                    const SizedBox(height: 6),
                    Text(
                      widget.album.artistName,
                      style: const TextStyle(color: Colors.white54),
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

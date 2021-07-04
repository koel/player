import 'package:app/models/artist.dart';
import 'package:flutter/material.dart';

enum ThumbnailSize { sm, md, lg, xl }

class ArtistThumbnail extends StatelessWidget {
  final Artist artist;
  final ThumbnailSize size;
  final bool asHero;

  const ArtistThumbnail({
    Key? key,
    required this.artist,
    this.size = ThumbnailSize.sm,
    this.asHero = false,
  }) : super(key: key);

  Widget imageBox() {
    return DecoratedBox(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: artist.image,
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: asHero
          ? Hero(
              tag: 'artist-hero-${artist.id}',
              child: imageBox(),
            )
          : imageBox(),
    );
  }

  double get width {
    switch (size) {
      case ThumbnailSize.lg:
        return 192;
      case ThumbnailSize.md:
        return 144;
      case ThumbnailSize.xl:
        return 256;
      default:
        return 40;
    }
  }

  double get borderRadius {
    switch (size) {
      case ThumbnailSize.md:
        return 12;
      case ThumbnailSize.lg:
        return 16;
      case ThumbnailSize.xl:
        return 20;
      default:
        return 20; // rounded for sm size
    }
  }

  double get height => width;
}

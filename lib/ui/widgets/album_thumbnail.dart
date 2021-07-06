import 'package:app/models/album.dart';
import 'package:app/ui/widgets/decorated_image_box.dart';
import 'package:flutter/material.dart';

enum ThumbnailSize { sm, md, lg, xl }

class AlbumThumbnail extends StatelessWidget {
  final Album album;
  final ThumbnailSize size;
  final bool asHero;

  const AlbumThumbnail({
    Key? key,
    required this.album,
    this.size = ThumbnailSize.sm,
    this.asHero = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget imageBox = DecoratedImageBox(
      image: album.image,
      borderRadius: borderRadius,
    );
    return SizedBox(
      width: width,
      height: height,
      child: asHero
          ? Hero(
              tag: 'album-hero-${album.id}',
              child: imageBox,
            )
          : imageBox,
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

import 'package:app/constants/images.dart';
import 'package:app/models/album.dart';
import 'package:app/utils/preferences.dart' as preferences;
import 'package:cached_network_image/cached_network_image.dart';
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
    Widget image = CachedNetworkImage(
      fit: BoxFit.cover,
      width: width,
      height: height,
      placeholder: (_, __) => defaultImage,
      errorWidget: (_, __, ___) => defaultImage,
      imageUrl: album.cover ?? preferences.defaultImageUrl,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: asHero
          ? Hero(
              tag: 'album-hero-${album.id}',
              child: image,
            )
          : image,
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

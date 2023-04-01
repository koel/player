import 'package:app/constants/constants.dart';
import 'package:app/models/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';

enum ThumbnailSize { sm, md, lg, xl }

class AlbumArtistThumbnail extends StatelessWidget {
  final dynamic entity;
  final ThumbnailSize size;
  final bool asHero;

  const AlbumArtistThumbnail({
    Key? key,
    required this.entity,
    this.size = ThumbnailSize.sm,
    this.asHero = false,
  })  : assert(entity is Artist || entity is Album),
        super(key: key);

  get imageUrl => entity is Artist ? entity.imageUrl : entity.cover;

  get heroTag =>
      entity is Artist ? 'artist-hero-${entity.id}' : 'album-hero-${entity.id}';

  @override
  Widget build(BuildContext context) {
    Widget image = imageUrl == null
        ? Image.asset(
            'assets/images/default-image.webp',
            fit: BoxFit.cover,
            width: width,
            height: height,
          )
        : CachedNetworkImage(
            fit: BoxFit.cover,
            width: width,
            height: height,
            placeholder: (_, __) => defaultImage,
            errorWidget: (_, __, ___) => defaultImage,
            imageUrl: imageUrl,
          );

    return ClipSmoothRect(
      radius: SmoothBorderRadius(
        cornerRadius: borderRadius,
        cornerSmoothing: .5,
      ),
      child: asHero ? Hero(tag: heroTag, child: image) : image,
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
        return 16;
      case ThumbnailSize.lg:
        return 24;
      case ThumbnailSize.xl:
        return 32;
      default:
        return 20; // rounded for sm size
    }
  }

  double get height => width;
}

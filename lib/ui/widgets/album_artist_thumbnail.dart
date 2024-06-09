import 'package:app/constants/constants.dart';
import 'package:app/enums.dart';
import 'package:app/models/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';

class AlbumArtistThumbnail extends StatelessWidget {
  final dynamic entity;
  final ThumbnailSize size;
  final bool asHero;

  const AlbumArtistThumbnail.sm({
    Key? key,
    required this.entity,
    this.asHero = false,
  })  : size = ThumbnailSize.sm,
        assert(entity is Artist || entity is Album || entity is Podcast),
        super(key: key);

  const AlbumArtistThumbnail.md({
    Key? key,
    required this.entity,
    this.asHero = false,
  })  : size = ThumbnailSize.md,
        assert(entity is Artist || entity is Album || entity is Podcast),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final dimension = dimensionForSize(size);
    final imageUrl = imageUrlForEntity(entity);

    Widget image = imageUrl == null
        ? Image.asset(
            AppImages.defaultImageAssetName,
            fit: BoxFit.cover,
            width: dimension,
            height: dimension,
          )
        : CachedNetworkImage(
            fit: BoxFit.cover,
            width: dimension,
            height: dimension,
            placeholder: (_, __) => AppImages.defaultImage,
            errorWidget: (_, __, ___) => AppImages.defaultImage,
            imageUrl: imageUrl,
          );

    return ClipSmoothRect(
      radius: SmoothBorderRadius(
        cornerRadius: borderRadiusForSize(size),
        cornerSmoothing: .8,
      ),
      child: asHero ? Hero(tag: tagForEntity(entity), child: image) : image,
    );
  }

  static double dimensionForSize(ThumbnailSize size) {
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

  static double borderRadiusForSize(ThumbnailSize size) {
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

  static String? imageUrlForEntity(dynamic entity) {
    if (entity is Artist) {
      return entity.imageUrl;
    } else if (entity is Album) {
      return entity.cover;
    } else if (entity is Podcast) {
      return entity.imageUrl;
    }

    throw ArgumentError('Entity must be Artist, Album or Podcast');
  }

  static String tagForEntity(dynamic entity) {
    if (entity is Artist) {
      return 'artist-hero-${entity.id}';
    } else if (entity is Album) {
      return 'album-hero-${entity.id}';
    } else if (entity is Podcast) {
      return 'podcast-hero-${entity.id}';
    }

    throw ArgumentError('Entity must be Artist, Album or Podcast');
  }
}

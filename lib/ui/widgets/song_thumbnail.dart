import 'package:app/constants/constants.dart';
import 'package:app/enums.dart';
import 'package:app/models/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';

class SongThumbnail extends StatelessWidget {
  final Song song;
  final ThumbnailSize size;
  final bool playing;

  const SongThumbnail({
    Key? key,
    required this.song,
    this.size = ThumbnailSize.sm,
    this.playing = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final albumCover = song.albumCoverUrl == null
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
            imageUrl: song.albumCoverUrl ?? '',
          );

    return ClipSmoothRect(
      radius: SmoothBorderRadius(
        cornerRadius: borderRadius,
        cornerSmoothing: .8,
      ),
      child: this.playing
          ? PlayingSongThumbnail(
              dimension: dimension,
              song: song,
              borderRadius: borderRadius,
            )
          : albumCover,
    );
  }

  double get dimension {
    switch (size) {
      case ThumbnailSize.lg:
        return 192;
      case ThumbnailSize.md:
        return 144;
      case ThumbnailSize.xl:
        return 256;
      default:
        return 48;
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
        return 8;
    }
  }
}

class PlayingSongThumbnail extends StatelessWidget {
  final double dimension;
  final Song song;
  final double borderRadius;

  const PlayingSongThumbnail({
    Key? key,
    required this.dimension,
    required this.song,
    required this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: dimension,
      child: Stack(
        children: <Widget>[
          SongThumbnail(song: song),
          SizedBox.square(
            dimension: double.infinity,
            child: DecoratedBox(
              decoration:
                  BoxDecoration(color: Color(0xFF410928).withOpacity(.7)),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: SizedBox.square(
              dimension: 16,
              child: Image.asset('assets/images/loading-animation.gif'),
            ),
          ),
        ],
      ),
    );
  }
}

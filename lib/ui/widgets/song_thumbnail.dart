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

  const SongThumbnail.xs({Key? key, required this.song, this.playing = false})
      : size = ThumbnailSize.xs,
        super(key: key);

  const SongThumbnail.sm({Key? key, required this.song, this.playing = false})
      : size = ThumbnailSize.sm,
        super(key: key);

  const SongThumbnail.md({Key? key, required this.song, this.playing = false})
      : size = ThumbnailSize.md,
        super(key: key);

  const SongThumbnail.lg({Key? key, required this.song, this.playing = false})
      : size = ThumbnailSize.lg,
        super(key: key);

  const SongThumbnail.xl({Key? key, required this.song, this.playing = false})
      : size = ThumbnailSize.xl,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final dimension = dimensionForSize(size);
    final borderRadius = borderRadiusForSize(size);

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
      child: this.playing ? PlayingSongThumbnail(song: song) : albumCover,
    );
  }

  static double dimensionForSize(ThumbnailSize size) {
    switch (size) {
      case ThumbnailSize.xs:
        return 36;
      case ThumbnailSize.md:
        return 144;
      case ThumbnailSize.lg:
        return 192;
      case ThumbnailSize.xl:
        return 256;
      default:
        return 48;
    }
  }

  static double borderRadiusForSize(ThumbnailSize size) {
    switch (size) {
      case ThumbnailSize.xs:
        return 8;
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
  final Song song;

  const PlayingSongThumbnail({Key? key, required this.song}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: SongThumbnail.dimensionForSize(ThumbnailSize.sm),
      child: Stack(
        children: <Widget>[
          SongThumbnail.sm(song: song),
          SizedBox.square(
            dimension: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFF410928).withOpacity(.7),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: SizedBox.square(
              dimension: 16.0,
              child: Image.asset('assets/images/loading-animation.gif'),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:app/constants/images.dart';
import 'package:app/models/song.dart';
import 'package:app/utils/preferences.dart' as preferences;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

enum ThumbnailSize { sm, md, lg, xl }

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
    return this.playing
        ? PlayingSongThumbnail(
            width: width,
            height: height,
            song: song,
            borderRadius: borderRadius,
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: CachedNetworkImage(
              fit: BoxFit.cover,
              width: width,
              height: height,
              placeholder: (_, __) => defaultImage,
              errorWidget: (_, __, ___) => defaultImage,
              imageUrl: song.imageUrl ?? preferences.defaultImageUrl,
            ),
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
        return 48;
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
        return 8;
    }
  }

  double get height => width;
}

class PlayingSongThumbnail extends StatelessWidget {
  final double width;
  final double height;
  final Song song;
  final double borderRadius;

  const PlayingSongThumbnail({
    Key? key,
    required this.width,
    required this.height,
    required this.song,
    required this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: <Widget>[
          SongThumbnail(song: song),
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
                color: Colors.black54,
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              child: Image.asset('assets/images/loading-animation.gif'),
              width: 16,
              height: 16,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:app/models/song.dart';
import 'package:flutter/material.dart';

enum ThumbnailSize { small, large, extraLarge }

class SongThumbnail extends StatelessWidget {
  final Song song;
  final ThumbnailSize size;

  const SongThumbnail({
    Key? key,
    required this.song,
    this.size = ThumbnailSize.small,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(image: song.image, fit: BoxFit.cover),
          borderRadius: BorderRadius.all(
            Radius.circular(borderRadius),
          ),
        ),
      ),
    );
  }

  double get width {
    switch (size) {
      case ThumbnailSize.large:
        return 144;
      case ThumbnailSize.extraLarge:
        return 256;
      default:
        return 48;
    }
  }

  double get borderRadius {
    switch (size) {
      case ThumbnailSize.large:
        return 16;
      case ThumbnailSize.extraLarge:
        return 20;
      default:
        return 8;
    }
  }

  double get height => width;
}

import 'package:app/models/song.dart';
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

  Widget simpleThumbnail() {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(image: song.image, fit: BoxFit.cover),
          borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
        ),
      ),
    );
  }

  Widget thumbnailWithPlayingIcon() {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          SongThumbnail(song: song),
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
                color: Colors.black.withOpacity(.7),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              child: Image.asset(
                'assets/images/loading-animation.gif',
              ),
              width: 16,
              height: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return this.playing ? thumbnailWithPlayingIcon() : simpleThumbnail();
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

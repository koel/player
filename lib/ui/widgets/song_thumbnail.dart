import 'package:app/models/song.dart';
import 'package:flutter/material.dart';

enum ThumbnailSize { small, large }

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
      width: size == ThumbnailSize.small ? 48 : 160,
      height: size == ThumbnailSize.small ? 48 : 160,
      child: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(image: song.image, fit: BoxFit.cover),
          borderRadius: BorderRadius.all(
            Radius.circular(size == ThumbnailSize.small ? 8 : 16),
          ),
        ),
      ),
    );
  }
}

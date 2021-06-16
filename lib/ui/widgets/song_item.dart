import 'package:app/constants/colors.dart';
import 'package:app/models/song.dart';
import 'package:flutter/material.dart';

class SongItem extends StatefulWidget {
  final Song song;

  const SongItem(this.song, {Key? key}) : super(key: key);

  @override
  _SongItem createState() => _SongItem();
}

class _SongItem extends State<SongItem> {
  @override
  Widget build(BuildContext context) {
    ImageProvider image = widget.song.album.cover == null
        ? AssetImage('assets/images/unknown-album.png')
        : NetworkImage(widget.song.album.cover!) as ImageProvider;

    return Row(
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(image: image, fit: BoxFit.cover),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
        SizedBox(width: 12, height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.song.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              widget.song.artist.name,
              style: TextStyle(
                color: AppColors.primaryText.withAlpha(192),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

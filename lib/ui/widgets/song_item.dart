import 'package:app/constants/colors.dart';
import 'package:app/models/song.dart';
import 'package:app/ui/widgets/song_thumbnail.dart';
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
    return Row(
      children: [
        SongThumbnail(song: widget.song),
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

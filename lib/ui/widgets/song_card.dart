import 'package:app/models/song.dart';
import 'package:flutter/material.dart';

class SongCard extends StatelessWidget {
  final Song song;

  SongCard(this.song, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ImageProvider image = song.album.cover == null
        ? AssetImage('assets/images/unknown-album.png')
        : NetworkImage(song.album.cover!) as ImageProvider;

    return new Column(
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(image: image, fit: BoxFit.cover),
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
        SizedBox(height: 8),
        SizedBox(
          width: 160,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                song.title,
                style: TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                song.artist.name,
                overflow: TextOverflow.ellipsis,
              )
            ],
          ),
        ),
      ],
    );
  }
}

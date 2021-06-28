import 'package:app/models/song.dart';
import 'package:app/ui/widgets/song_row.dart';
import 'package:flutter/material.dart';

enum SongListBehavior { queue, none }

class SongList extends StatefulWidget {
  final List<Song> songs;
  final SongListBehavior behavior;

  SongList({
    Key? key,
    required this.songs,
    this.behavior = SongListBehavior.none,
  }) : super(key: key);

  @override
  _SongListState createState() => _SongListState();
}

class _SongListState extends State<SongList> {
  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return SongRow(
            song: widget.songs[index],
            behavior: widget.behavior,
          );
        },
        childCount: widget.songs.length,
      ),
    );
  }
}

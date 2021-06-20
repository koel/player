import 'package:app/models/song.dart';
import 'package:app/ui/widgets/song_row.dart';
import 'package:flutter/material.dart';

class SongList extends StatefulWidget {
  final List<Song> songs;

  SongList({Key? key, required this.songs}) : super(key: key);

  @override
  _SongListState createState() => _SongListState();
}

class _SongListState extends State<SongList> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return SongRow(song: widget.songs[index]);
        },
        childCount: widget.songs.length,
      ),
    );
  }
}

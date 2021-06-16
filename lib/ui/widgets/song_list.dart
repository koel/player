import 'package:app/models/song.dart';
import 'package:flutter/material.dart';

class SongList extends StatefulWidget {
  final List<Song> songs;

  SongList(this.songs, {Key? key}) : super(key: key);

  @override
  _SongListState createState() => _SongListState();
}

class _SongListState extends State<SongList> {
  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          Song _song = widget.songs[index];
          return Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade800, width: 0.5),
              ),
            ),
            child: ListTile(
              leading: SizedBox(
                height: 48,
                width: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: _song.image,
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              ),
              title: Text(_song.title, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                _song.album.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
        childCount: widget.songs.length,
      ),
    );
  }
}

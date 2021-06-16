import 'package:app/constants/colors.dart';
import 'package:app/models/song.dart';
import 'package:flutter/cupertino.dart';
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
          return ListTile(
            shape: Border(
              bottom: BorderSide(color: Colors.grey.shade800, width: 0.5),
            ),
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
            trailing: GestureDetector(
              onTapDown: (TapDownDetails details) => _openContextMenu(
                context,
                details,
                _song,
              ),
              child: Icon(
                Icons.more_horiz,
              ),
            ),
          );
        },
        childCount: widget.songs.length,
      ),
    );
  }

  _openContextMenu(
    BuildContext context,
    TapDownDetails details,
    Song song,
  ) async {
    await showMenu(
      context: context,
      items: <PopupMenuEntry>[
        PopupMenuItem(
          padding: EdgeInsets.all(0),
          child: ListTile(
            title: Text('Play Now'),
            trailing: Icon(Icons.play_circle_outline),
          ),
        ),
        PopupMenuItem(
          padding: EdgeInsets.all(0),
          child: ListTile(
            title: Text('Play Next'),
            trailing: Icon(Icons.queue_music),
          ),
        ),
        PopupMenuItem(
          padding: EdgeInsets.all(0),
          child: ListTile(
            title: Text('Play Last'),
            trailing: Icon(Icons.queue_music),
          ),
        ),
        PopupMenuItem(
          padding: EdgeInsets.all(0),
          child: ListTile(
            title: Text('Add to a Playlist…'),
            trailing: Icon(Icons.playlist_add),
          ),
        ),
        PopupMenuItem(
          padding: EdgeInsets.all(0),
          child: ListTile(
            title: Text(song.liked ? 'Unlove' : 'Love'),
            trailing: Icon(song.liked ? Icons.favorite : Icons.favorite_border),
          ),
        ),
      ],
      position: RelativeRect.fromLTRB(
          details.globalPosition.dx, details.globalPosition.dy, 20, 16),
    );
  }
}

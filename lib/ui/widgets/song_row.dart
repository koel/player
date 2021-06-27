import 'package:app/models/song.dart';
import 'package:app/providers/audio_player_provider.dart';
import 'package:app/ui/widgets/song_thumbnail.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SongRow extends StatefulWidget {
  final Song song;
  final bool bordered;
  final EdgeInsetsGeometry? padding;

  SongRow({Key? key, required this.song, this.bordered = true, this.padding})
      : super(key: key);

  @override
  _SongRowState createState() => _SongRowState();
}

class _SongRowState extends State<SongRow> {
  late AudioPlayerProvider audio;
  PlayerState _state = PlayerState.stop;

  @override
  void initState() {
    super.initState();
    audio = context.read<AudioPlayerProvider>();
    audio.player.playerState.listen((PlayerState state) {
      setState(() => _state = state);
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async => await audio.play(song: widget.song),
      child: ListTile(
        contentPadding: widget.padding,
        shape: widget.bordered
            ? Border(
                bottom: BorderSide(color: Colors.grey.shade800, width: 0.5),
              )
            : null,
        leading: StreamBuilder<Playing?>(
          stream: audio.player.current,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return SizedBox();
            }

            bool playing = snapshot.data!.audio.audio.metas.extra?['songId'] ==
                    widget.song.id &&
                _state == PlayerState.play;

            return SongThumbnail(song: widget.song, playing: playing);
          },
        ),
        title: Text(widget.song.title, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          widget.song.album.name,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: GestureDetector(
          onTapDown: (TapDownDetails details) => _openContextMenu(
            context,
            details,
            widget.song,
          ),
          child: Icon(CupertinoIcons.ellipsis, size: 20),
        ),
      ),
    );
  }

  Future<void> _openContextMenu(
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
            trailing: Icon(CupertinoIcons.play_circle),
            onTap: () async => await audio.play(song: song),
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
            title: Text('Add to Queue'),
            trailing: Icon(Icons.queue_music),
            // onTap: () async =>
            //     await AudioService.addQueueItem(await song.asMediaItem()),
          ),
        ),
        PopupMenuItem(
          padding: EdgeInsets.all(0),
          child: ListTile(
            title: Text('Add to a Playlist…'),
            trailing: Icon(CupertinoIcons.text_badge_plus),
          ),
        ),
        PopupMenuItem(
          padding: EdgeInsets.all(0),
          child: ListTile(
            title: Text(song.liked ? 'Unlove' : 'Love'),
            trailing: Icon(
              song.liked
                  ? CupertinoIcons.heart_slash
                  : CupertinoIcons.heart_solid,
            ),
          ),
        ),
      ],
      position: RelativeRect.fromLTRB(
          details.globalPosition.dx, details.globalPosition.dy, 20, 16),
    );
  }
}

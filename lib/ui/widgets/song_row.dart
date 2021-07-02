import 'dart:async';

import 'package:app/models/song.dart';
import 'package:app/providers/audio_player_provider.dart';
import 'package:app/providers/song_provider.dart';
import 'package:app/ui/screens/song_action_sheet.dart';
import 'package:app/ui/widgets/song_list.dart';
import 'package:app/ui/widgets/song_thumbnail.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SongRow extends StatefulWidget {
  final Song song;
  final bool bordered;
  final EdgeInsetsGeometry? padding;
  final SongListBehavior behavior;

  SongRow({
    Key? key,
    required this.song,
    this.bordered = true,
    this.padding,
    this.behavior = SongListBehavior.none,
  }) : super(key: key);

  @override
  _SongRowState createState() => _SongRowState();
}

class _SongRowState extends State<SongRow> {
  late AudioPlayerProvider audio;
  late SongProvider songProvider;
  PlayerState _state = PlayerState.stop;
  bool _isCurrentSong = false;
  List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    audio = context.read<AudioPlayerProvider>();
    _subscriptions.add(audio.player.playerState.listen((PlayerState state) {
      setState(() => _state = state);
    }));
    _subscriptions.add(audio.player.current.listen((Playing? current) {
      setState(() => _isCurrentSong =
          current?.audio.audio.metas.extra?['songId'] == widget.song.id);
    }));
    songProvider = context.read<SongProvider>();
  }

  @override
  void dispose() {
    _subscriptions.forEach((element) => element.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async => await audio.play(song: widget.song),
      child: ListTile(
        key: UniqueKey(),
        contentPadding: widget.padding,
        shape: widget.bordered
            ? Border(bottom: Divider.createBorderSide(context))
            : null,
        leading: SongThumbnail(
          song: widget.song,
          playing: _state == PlayerState.play && _isCurrentSong,
        ),
        title: Text(widget.song.title, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          widget.song.album.name,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: Icon(CupertinoIcons.ellipsis, size: 20),
          onPressed: () {
            showActionSheet(
              context: context,
              song: widget.song,
            );
          },
        ),
      ),
    );
  }
}

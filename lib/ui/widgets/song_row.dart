import 'dart:async';

import 'package:app/extensions/assets_audio_player.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/audio_player_provider.dart';
import 'package:app/providers/song_provider.dart';
import 'package:app/ui/screens/song_action_sheet.dart';
import 'package:app/ui/widgets/song_cache_icon.dart';
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

  /// The index of the row in a list, important for (Sliver) orderable lists.
  final int index;

  SongRow({
    Key? key,
    required this.song,
    this.bordered = true,
    this.padding,
    this.behavior = SongListBehavior.none,
    this.index = 0,
  }) : super(key: key);

  @override
  _SongRowState createState() => _SongRowState();
}

class _SongRowState extends State<SongRow> {
  late AudioPlayerProvider audio;

  @override
  void initState() {
    super.initState();
    audio = context.read();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async => await audio.play(song: widget.song),
      onLongPress: () => showActionSheet(context: context, song: widget.song),
      child: ListTile(
        key: UniqueKey(),
        contentPadding: widget.padding,
        shape: widget.bordered
            ? Border(bottom: Divider.createBorderSide(context))
            : null,
        leading: SongRowThumbnail(song: widget.song),
        title: Text(widget.song.title, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          widget.song.album.name,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: SongRowTrailingActions(
          song: widget.song,
          behavior: widget.behavior,
          index: widget.index,
        ),
      ),
    );
  }
}

class SongRowThumbnail extends StatefulWidget {
  final Song song;

  const SongRowThumbnail({Key? key, required this.song}) : super(key: key);

  @override
  _SongRowThumbnailState createState() => _SongRowThumbnailState();
}

class _SongRowThumbnailState extends State<SongRowThumbnail> {
  late AudioPlayerProvider audio;
  late SongProvider songProvider;
  PlayerState _state = PlayerState.stop;
  bool _isCurrentSong = false;
  List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();

    audio = context.read();

    _subscriptions.add(audio.player.playerState.listen((PlayerState state) {
      setState(() => _state = state);
    }));

    _subscriptions.add(audio.player.current.listen((Playing? current) {
      setState(() => _isCurrentSong = audio.player.songId == widget.song.id);
    }));

    songProvider = context.read();
  }

  @override
  void dispose() {
    super.dispose();
    _subscriptions.forEach((sub) => sub.cancel());
  }

  @override
  Widget build(BuildContext context) {
    return SongThumbnail(
      song: widget.song,
      playing: _state == PlayerState.play && _isCurrentSong,
    );
  }
}

class SongRowTrailingActions extends StatelessWidget {
  final SongListBehavior behavior;
  final Song song;
  final int index;

  const SongRowTrailingActions({
    Key? key,
    required this.song,
    required this.behavior,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SongCacheIcon(song: song),
        behavior == SongListBehavior.queue
            // In a queue, the trailing control is the Drag icon
            // In other "standard" queues, it's the Actions menu trigger
            ? ReorderableDragStartListener(
                index: index,
                child: Icon(
                  CupertinoIcons.bars,
                  color: Colors.white.withOpacity(.5),
                ),
              )
            : IconButton(
                icon: const Icon(CupertinoIcons.ellipsis, size: 20),
                onPressed: () => showActionSheet(
                  context: context,
                  song: song,
                ),
              ),
      ],
    );
  }
}

import 'package:app/extensions/assets_audio_player.dart';
import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/audio_provider.dart';
import 'package:app/ui/screens/song_action_sheet.dart';
import 'package:app/ui/widgets/song_cache_icon.dart';
import 'package:app/ui/widgets/song_list_buttons.dart';
import 'package:app/ui/widgets/song_thumbnail.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/style.dart';
import 'package:provider/provider.dart';

class SongRow extends StatefulWidget {
  final Song song;
  final bool bordered;
  final EdgeInsetsGeometry? padding;
  final SongListContext listContext;

  /// The index of the row in a list, important for (Sliver) orderable lists.
  final int index;

  SongRow({
    Key? key,
    required this.song,
    this.bordered = true,
    this.padding,
    this.listContext = SongListContext.other,
    this.index = 0,
  }) : super(key: key);

  @override
  _SongRowState createState() => _SongRowState();
}

class _SongRowState extends State<SongRow> {
  late AudioProvider audio;

  @override
  void initState() {
    super.initState();
    audio = context.read();
  }

  @override
  Widget build(BuildContext context) {
    late String subtitle;

    switch (widget.listContext) {
      case SongListContext.album:
      case SongListContext.artist:
        subtitle = widget.song.album.name;
        break;
      default:
        subtitle = widget.song.artist.name;
        break;
    }

    return InkWell(
      onTap: () async => await audio.play(song: widget.song),
      onLongPress: () {
        HapticFeedback.mediumImpact();
        showActionSheet(context: context, song: widget.song);
      },
      child: ListTile(
        key: UniqueKey(),
        contentPadding: widget.padding,
        shape: widget.bordered
            ? Border(bottom: Divider.createBorderSide(context))
            : null,
        leading: widget.listContext == SongListContext.album
            ? SongRowTrackNumber(song: widget.song)
            : SongRowThumbnail(song: widget.song),
        minLeadingWidth: widget.listContext == SongListContext.album ? 0 : null,
        title: Text(widget.song.title, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          subtitle,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white60),
        ),
        trailing: SongRowTrailingActions(
          song: widget.song,
          listContext: widget.listContext,
          index: widget.index,
        ),
      ),
    );
  }
}

class SongRowTrackNumber extends StatelessWidget {
  final Song song;

  const SongRowTrackNumber({Key? key, required this.song}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 48,
      alignment: Alignment.center,
      child: Text(
        song.track == 0 ? '' : song.track.toString(),
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: FontSize.large.size, color: Colors.white54),
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

class _SongRowThumbnailState extends State<SongRowThumbnail>
    with StreamSubscriber {
  late AudioProvider audio;
  PlayerState _state = PlayerState.stop;
  bool _isCurrentSong = false;

  @override
  void initState() {
    super.initState();

    audio = context.read();

    subscribe(audio.player.playerState.listen((PlayerState state) {
      setState(() => _state = state);
    }));

    subscribe(audio.player.current.listen((Playing? current) {
      setState(() => _isCurrentSong = audio.player.songId == widget.song.id);
    }));
  }

  @override
  void dispose() {
    unsubscribeAll();
    super.dispose();
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
  final SongListContext listContext;
  final Song song;
  final int index;

  const SongRowTrailingActions({
    Key? key,
    required this.song,
    required this.listContext,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SongCacheIcon(song: song),
        if (listContext == SongListContext.queue)
          // In a queue, the trailing control is the Drag icon
          // In other "standard" queues, it's the Actions menu trigger
          ReorderableDragStartListener(
            index: index,
            child: Container(
              padding: EdgeInsets.only(left: 12),
              child: Icon(
                CupertinoIcons.bars,
                color: Colors.white54,
              ),
            ),
          )
        else
          IconButton(
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

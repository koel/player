import 'package:app/main.dart';
import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/router.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/style.dart';

class SongRow extends StatefulWidget {
  final Song song;
  final bool bordered;
  final SongListContext listContext;

  /// The index of the row in a list, important for (Sliver) orderable lists.
  final int index;

  final AppRouter router;

  SongRow({
    Key? key,
    required this.song,
    this.bordered = true,
    this.listContext = SongListContext.other,
    this.index = 0,
    this.router = const AppRouter(),
  }) : super(key: key);

  @override
  _SongRowState createState() => _SongRowState();
}

class _SongRowState extends State<SongRow> {
  @override
  Widget build(BuildContext context) {
    late String subtitle;

    switch (widget.listContext) {
      case SongListContext.album:
      case SongListContext.artist:
        subtitle = widget.song.albumName;
        break;
      default:
        subtitle = widget.song.artistName;
        break;
    }

    return Card(
      child: InkWell(
        onTap: () => audioHandler.queueAndPlay(widget.song),
        onLongPress: () {
          HapticFeedback.mediumImpact();
          widget.router.showActionSheet(context, song: widget.song);
        },
        child: ListTile(
          key: UniqueKey(),
          shape: widget.bordered
              ? Border(bottom: Divider.createBorderSide(context))
              : null,
          leading: widget.listContext == SongListContext.album
              ? SongRowTrackNumber(song: widget.song)
              : SongRowThumbnail(song: widget.song),
          minLeadingWidth:
              widget.listContext == SongListContext.album ? 0 : null,
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
  PlaybackState? _state;
  bool _isCurrentSong = false;

  @override
  void initState() {
    super.initState();

    subscribe(audioHandler.playbackState.listen((PlaybackState value) {
      setState(() => _state = value);
    }));

    subscribe(audioHandler.mediaItem.listen((MediaItem? value) {
      setState(() => _isCurrentSong = value?.id == widget.song.id);
    }));
  }

  @override
  void dispose() {
    unsubscribeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;

    return SongThumbnail(
      song: widget.song,
      playing: state != null &&
          state.playing &&
          state.processingState != AudioProcessingState.completed &&
          state.processingState != AudioProcessingState.error &&
          _isCurrentSong,
    );
  }
}

class SongRowTrailingActions extends StatelessWidget {
  final SongListContext listContext;
  final Song song;
  final int index;
  final AppRouter router;

  const SongRowTrailingActions({
    Key? key,
    required this.song,
    required this.listContext,
    required this.index,
    this.router = const AppRouter(),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (listContext != SongListContext.downloads) SongCacheIcon(song: song),
        if (listContext == SongListContext.queue)
          // In a queue, the trailing control is the Drag icon
          // In other "standard" queues, it's the Actions menu trigger
          ReorderableDragStartListener(
            index: index,
            child: Container(
              padding: const EdgeInsets.only(left: 12),
              child: const Icon(CupertinoIcons.bars, color: Colors.white54),
            ),
          )
        else
          IconButton(
            icon: const Icon(CupertinoIcons.ellipsis, size: 20),
            padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
            constraints: BoxConstraints(),
            onPressed: () => router.showActionSheet(
              context,
              song: song,
            ),
          ),
      ],
    );
  }
}

import 'package:app/app_state.dart';
import 'package:app/enums.dart';
import 'package:app/main.dart';
import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/router.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:app/utils/features.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:provider/provider.dart';

import 'package:intl/intl.dart';

class PlayableRow extends StatefulWidget {
  final Playable playable;
  final bool bordered;
  final PlayableListContext listContext;

  /// The index of the row in a list, important for (Sliver) orderable lists.
  final int index;

  final AppRouter router;

  PlayableRow({
    Key? key,
    required this.playable,
    this.bordered = true,
    this.listContext = PlayableListContext.other,
    this.index = 0,
    this.router = const AppRouter(),
  }) : super(key: key);

  @override
  _PlayableRowState createState() => _PlayableRowState();
}

class _PlayableRowState extends State<PlayableRow> {
  Future<num> getPlaybackStartPosition(Playable playable) async {
    if (!Feature.podcasts.isSupported()) {
      return 0;
    }

    if (AppState.get('mode', AppMode.online) == AppMode.offline) {
      return 0;
    }

    if (playable is Episode) {
      var position = audioHandler.getPlaybackPositionFromState(playable.id);

      if (position != null) {
        return position;
      }

      position =
          await context.read<PodcastProvider>().getEpisodeProgress(playable);
      audioHandler.setPlaybackPositionToState(playable.id, position);

      return position;
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    late String subtitle;

    switch (widget.listContext) {
      case PlayableListContext.album:
      case PlayableListContext.artist:
        subtitle = (widget.playable as Song).albumName;
        break;
      case PlayableListContext.podcast:
        var createdAt = (widget.playable as Episode).createdAt;
        // To be more user-friendly, we display the human readable format,
        // but not for too old (>6 months in the past) dates.
        subtitle =
            DateTime.now().difference(createdAt) > const Duration(days: 180)
                ? DateFormat.yMMMd().format(createdAt)
                : timeago.format(createdAt);
        break;
      default:
        if (widget.playable is Episode)
          subtitle = (widget.playable as Episode).podcastTitle;
        else if (widget.playable is Song)
          subtitle = (widget.playable as Song).artistName;
        break;
    }

    return Card(
      child: InkWell(
        onTap: () async => await audioHandler.maybeQueueAndPlay(
          widget.playable,
          position: await getPlaybackStartPosition(widget.playable),
        ),
        onLongPress: () {
          HapticFeedback.mediumImpact();
          widget.router.showPlayableActionSheet(
            context,
            playable: widget.playable,
          );
        },
        child: ListTile(
          key: UniqueKey(),
          shape: widget.bordered
              ? Border(bottom: Divider.createBorderSide(context))
              : null,
          leading: widget.listContext == PlayableListContext.album
              ? PlayableRowTrackNumber(song: widget.playable as Song)
              : widget.listContext == PlayableListContext.podcast
                  ? null
                  : PlayableRowThumbnail(playable: widget.playable),
          minLeadingWidth:
              widget.listContext == PlayableListContext.album ? 0 : null,
          title: Text(widget.playable.title, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            subtitle,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white60),
          ),
          trailing: PlayableRowTrailingActions(
            playable: widget.playable,
            listContext: widget.listContext,
            index: widget.index,
          ),
        ),
      ),
    );
  }
}

class PlayableRowTrackNumber extends StatelessWidget {
  final Song song;

  const PlayableRowTrackNumber({
    Key? key,
    required this.song,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 48,
      alignment: Alignment.center,
      child: Text(
        song.track == 0 ? '' : song.track.toString(),
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 15, color: Colors.white54),
      ),
    );
  }
}

class PlayableRowThumbnail extends StatefulWidget {
  final Playable playable;

  const PlayableRowThumbnail({
    Key? key,
    required this.playable,
  }) : super(key: key);

  @override
  _PlayableRowThumbnailState createState() => _PlayableRowThumbnailState();
}

class _PlayableRowThumbnailState extends State<PlayableRowThumbnail>
    with StreamSubscriber {
  PlaybackState? _state;
  bool _isCurrentPlayable = false;

  @override
  void initState() {
    super.initState();

    subscribe(audioHandler.playbackState.listen((PlaybackState value) {
      setState(() => _state = value);
    }));

    subscribe(audioHandler.mediaItem.listen((MediaItem? value) {
      setState(() => _isCurrentPlayable = value?.id == widget.playable.id);
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

    return PlayableThumbnail.sm(
      playable: widget.playable,
      playing: state != null &&
          state.playing &&
          state.processingState != AudioProcessingState.completed &&
          state.processingState != AudioProcessingState.error &&
          _isCurrentPlayable,
    );
  }
}

class PlayableRowTrailingActions extends StatelessWidget {
  final PlayableListContext listContext;
  final Playable playable;
  final int index;
  final AppRouter router;

  const PlayableRowTrailingActions({
    Key? key,
    required this.playable,
    required this.listContext,
    required this.index,
    this.router = const AppRouter(),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (listContext != PlayableListContext.downloads)
          PlayableCacheIcon(playable: playable),
        if (listContext == PlayableListContext.queue)
          // In a queue, the trailing control is the Drag icon
          // In other "standard" queues, it's the Actions menu trigger
          ReorderableDragStartListener(
            index: index,
            child: const Icon(CupertinoIcons.bars, color: Colors.white54),
          )
        else
          GestureDetector(
            onTap: () => router.showPlayableActionSheet(
              context,
              playable: playable,
            ),
            child: const Icon(CupertinoIcons.ellipsis, size: 16),
          ),
      ],
    );
  }
}

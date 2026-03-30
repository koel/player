import 'dart:ui';

import 'package:app/main.dart';
import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/router.dart';
import 'package:app/ui/screens/screens.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NowPlayingScreen extends StatefulWidget {
  final AppRouter router;

  const NowPlayingScreen({
    Key? key,
    this.router = const AppRouter(),
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen>
    with StreamSubscriber {
  PlaybackState? _state;
  Playable? _playable;
  late PlayableProvider _playableProvider;
  var _dragOffset = 0.0;
  var _queuePlayables = <Playable>[];
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _playableProvider = context.read();

    subscribe(audioHandler.playbackState.listen((PlaybackState value) {
      setState(() => _state = value);
    }));

    subscribe(audioHandler.mediaItem.listen((MediaItem? value) {
      if (value == null) return;
      setState(() => _playable = _playableProvider.byId(value.id));
    }));

    subscribe(audioHandler.queue.listen((List<MediaItem> value) {
      setState(() {
        _queuePlayables = value
            .map((item) => _playableProvider.byId(item.id))
            .where((p) => p != null)
            .cast<Playable>()
            .toList();
      });
    }));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    unsubscribeAll();
    super.dispose();
  }

  void _onPointerMove(PointerMoveEvent event) {
    final atTop = !_scrollController.hasClients ||
        _scrollController.offset <= 0;

    if (_dragOffset > 0) {
      // Already dismissing — track in both directions
      setState(() {
        _dragOffset = (_dragOffset + event.delta.dy).clamp(0.0, double.infinity);
      });
    } else if (atTop && event.delta.dy > 0) {
      // At top and dragging down — start dismiss
      setState(() {
        _dragOffset = event.delta.dy;
      });
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_dragOffset <= 0) return;

    final screenHeight = MediaQuery.of(context).size.height;

    if (_dragOffset > screenHeight * 0.15) {
      Navigator.of(context).pop();
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final playable = _playable;

    if (playable == null || _state == null) return const SizedBox.shrink();

    final bottomIconColor = Colors.white54;
    final screenHeight = MediaQuery.of(context).size.height;

    final frostBackground = SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: ClipRect(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: playable.image,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
        ),
      ),
    );

    return Listener(
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      child: AnimatedContainer(
        duration:
            _dragOffset == 0 ? const Duration(milliseconds: 200) : Duration.zero,
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _dragOffset, 0),
        child: ClipRRect(
          borderRadius: Theme.of(context).platform == TargetPlatform.iOS
              ? const BorderRadius.vertical(top: Radius.circular(38.5))
              : BorderRadius.zero,
          child: Material(
            type: MaterialType.transparency,
            child: Stack(
              children: <Widget>[
                const GradientDecoratedContainer(),
                frostBackground,
                Container(color: Colors.black38),
                CustomScrollView(
                  controller: _scrollController,
                  // Freeze scroll while dismissing; bounce normally otherwise
                  physics: _dragOffset > 0
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Container(
                        height: _queuePlayables.isEmpty
                            ? screenHeight
                            : screenHeight - 106,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Center(
                              child: Container(
                                width: 36,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.white30,
                                  borderRadius: BorderRadius.circular(2.5),
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 24),
                              child: Hero(
                                tag: 'hero-now-playing-thumbnail',
                                child: PlayableThumbnail.xl(
                                    playable: playable),
                              ),
                            ),
                            Column(
                              children: <Widget>[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Expanded(
                                        child: PlayableInfo(
                                            playable: playable)),
                                    const SizedBox(width: 8),
                                    PlayableCacheIcon(playable: playable),
                                    GestureDetector(
                                      onTap: () => widget.router
                                          .showPlayableActionSheet(
                                        context,
                                        playable: playable,
                                      ),
                                      child: const Icon(
                                          CupertinoIcons.ellipsis),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ProgressBar(playable: playable),
                              ],
                            ),
                            const AudioControls(),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const VolumeSlider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    const RepeatModeButton(),
                                    IconButton(
                                      onPressed: () => showInfoSheet(
                                        context,
                                        playable: playable,
                                      ),
                                      icon: Icon(
                                        CupertinoIcons.text_quote,
                                        color: bottomIconColor,
                                      ),
                                    ),
                                    if (playable is Song)
                                      IconButton(
                                        onPressed: () {
                                          context
                                              .read<InteractionProvider>()
                                              .toggleLike(
                                                  song: playable as Song);
                                          setState(() {});
                                        },
                                        icon: Icon(
                                          playable.liked
                                              ? CupertinoIcons.star_fill
                                              : CupertinoIcons.star,
                                          color: playable.liked
                                              ? Colors.white
                                              : bottomIconColor,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_queuePlayables.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 16, right: 8, top: 4, bottom: 4),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Queued',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () async =>
                                    await audioHandler.clearQueue(),
                                child: const Text(
                                  'Clear',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverReorderableList(
                        itemCount: _queuePlayables.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Dismissible(
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) async {
                              await audioHandler
                                  .removeQueueItemAt(index);
                            },
                            background: Container(
                              alignment:
                                  AlignmentDirectional.centerEnd,
                              color: Colors.red,
                              child: const Padding(
                                padding: EdgeInsets.only(right: 16),
                                child:
                                    Icon(CupertinoIcons.delete),
                              ),
                            ),
                            key: ValueKey(_queuePlayables[index]),
                            child: PlayableRow(
                              index: index,
                              key: ValueKey(
                                  _queuePlayables[index]),
                              playable: _queuePlayables[index],
                              listContext:
                                  PlayableListContext.queue,
                            ),
                          );
                        },
                        onReorder: audioHandler.moveQueueItem,
                      ),
                      const BottomSpace(height: 120),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

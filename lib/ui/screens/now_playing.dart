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
  }

  @override
  void dispose() {
    unsubscribeAll();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (details.delta.dy < 0 && _dragOffset <= 0) return;
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dy).clamp(0.0, double.infinity);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final screenHeight = MediaQuery.of(context).size.height;
    final velocity = details.primaryVelocity ?? 0;

    if (_dragOffset > screenHeight * 0.2 || velocity > 800) {
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

    final thumbnail = Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Hero(
        tag: 'hero-now-playing-thumbnail',
        child: PlayableThumbnail.xl(playable: playable),
      ),
    );

    final infoPane = Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(child: PlayableInfo(playable: playable)),
            const SizedBox(width: 8),
            PlayableCacheIcon(playable: playable),
            GestureDetector(
              onTap: () => widget.router.showPlayableActionSheet(
                context,
                playable: playable,
              ),
              child: const Icon(CupertinoIcons.ellipsis),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ProgressBar(playable: playable),
      ],
    );

    return GestureDetector(
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      child: AnimatedContainer(
        duration: _dragOffset == 0
            ? const Duration(milliseconds: 200)
            : Duration.zero,
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
        Container(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints.tightFor(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                // Drag handle
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
                thumbnail,
                infoPane,
                const AudioControls(),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const VolumeSlider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                        IconButton(
                          onPressed: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            Navigator.of(context, rootNavigator: true)
                                .pushNamed(QueueScreen.routeName);
                          },
                          icon: Icon(
                            CupertinoIcons.list_number,
                            color: bottomIconColor,
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
      ],
    ),
    ),
    ),
    ),
    );
  }
}

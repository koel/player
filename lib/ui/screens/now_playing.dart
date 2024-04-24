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
  Song? _song;
  late SongProvider _songProvider;

  @override
  void initState() {
    super.initState();

    _songProvider = context.read();

    subscribe(audioHandler.playbackState.listen((PlaybackState value) {
      setState(() => _state = value);
    }));

    subscribe(audioHandler.mediaItem.listen((MediaItem? value) {
      if (value == null) return;
      setState(() => _song = _songProvider.byId(value.id));
    }));
  }

  @override
  void dispose() {
    unsubscribeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final song = _song;

    if (song == null || _state == null) return const SizedBox.shrink();

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
                image: song.image,
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
        child: SongThumbnail.xl(song: song),
      ),
    );

    final infoPane = Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(child: SongInfo(song: song)),
            const SizedBox(width: 8),
            SongCacheIcon(song: song),
            IconButton(
              onPressed: () =>
                  widget.router.showActionSheet(context, song: song),
              icon: const Icon(CupertinoIcons.ellipsis),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ProgressBar(song: song),
      ],
    );

    return Stack(
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
                          onPressed: () => showInfoSheet(context, song: song),
                          icon: Icon(
                            CupertinoIcons.text_quote,
                            color: bottomIconColor,
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              Navigator.of(context, rootNavigator: true)
                                  .pushNamed(QueueScreen.routeName),
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
    );
  }
}

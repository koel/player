import 'package:app/constants/constants.dart';
import 'package:app/enums.dart';
import 'package:app/main.dart';
import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/models/playable.dart';
import 'package:app/providers/providers.dart';
import 'package:app/router.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:audio_service/audio_service.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

class MiniPlayer extends StatefulWidget {
  static Key pauseButtonKey = UniqueKey();
  static Key nextButtonKey = UniqueKey();

  final AppRouter router;

  const MiniPlayer({
    Key? key,
    this.router = const AppRouter(),
  }) : super(key: key);

  @override
  _MiniPlayerState createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> with StreamSubscriber {
  late PlayableProvider _playableProvider;
  PlaybackState? _state;
  Playable? _playable;

  @override
  void initState() {
    super.initState();
    _playableProvider = context.read();

    subscribe(audioHandler.playbackState.listen((PlaybackState value) {
      setState(() => _state = value);
    }));

    subscribe(audioHandler.mediaItem.listen((MediaItem? value) {
      if (value != null) {
        setState(() => _playable = _playableProvider.byId(value.id));
      }
    }));
  }

  @override
  void dispose() {
    unsubscribeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playable = _playable;
    final state = _state;

    if (playable == null || state == null) return SizedBox.shrink();

    late final Widget statusIndicator;
    late final bool isLoading;

    if ((state.processingState == AudioProcessingState.buffering ||
            state.processingState == AudioProcessingState.loading) &&
        state.playing) {
      statusIndicator = SpinKitThreeBounce(color: AppColors.white, size: 16);
      isLoading = true;
    } else {
      // statusIndicator = SizedBox.shrink();
      statusIndicator = SpinKitThreeBounce(color: AppColors.white, size: 16);
      isLoading = false;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: ClipSmoothRect(
        radius: SmoothBorderRadius(
          cornerRadius: 14.0,
          cornerSmoothing: .8,
        ),
        child: FrostedGlassBackground(
          sigma: 20.0,
          child: Container(
            color: Color.fromRGBO(25, 0, 64, .5),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11.0,
                    vertical: 3.0,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.white.withOpacity(0.1),
                      width: .5,
                    ),
                  ),
                  child: InkWell(
                    onTap: () => widget.router.openNowPlayingScreen(context),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Stack(
                              children: [
                                Hero(
                                  tag: 'hero-now-playing-thumbnail',
                                  child: PlayableThumbnail.xs(
                                    playable: playable,
                                  ),
                                ),
                                if (isLoading)
                                  SizedBox.square(
                                    dimension:
                                        PlayableThumbnail.dimensionForSize(
                                      ThumbnailSize.xs,
                                    ),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(
                                            PlayableThumbnail
                                                .borderRadiusForSize(
                                              ThumbnailSize.xs,
                                            ),
                                          ),
                                        ),
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                if (isLoading)
                                  SizedBox.square(
                                    dimension:
                                        PlayableThumbnail.dimensionForSize(
                                      ThumbnailSize.xs,
                                    ),
                                    child: statusIndicator,
                                  ),
                              ],
                            ),
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  playable.title,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                IconButton(
                                  key: MiniPlayer.pauseButtonKey,
                                  onPressed: audioHandler.playOrPause,
                                  icon: Icon(
                                    state.playing
                                        ? CupertinoIcons.pause_fill
                                        : CupertinoIcons.play_fill,
                                    size: 24,
                                  ),
                                ),
                                IconButton(
                                  key: MiniPlayer.nextButtonKey,
                                  onPressed: audioHandler.skipToNext,
                                  icon: const Icon(
                                    CupertinoIcons.forward_fill,
                                    size: 24,
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: const MiniPlayerProgressBar(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MiniPlayerProgressBar extends StatefulWidget {
  const MiniPlayerProgressBar({Key? key}) : super(key: key);

  @override
  _MiniPlayerProgressBarState createState() => _MiniPlayerProgressBarState();
}

class _MiniPlayerProgressBarState extends State<MiniPlayerProgressBar>
    with StreamSubscriber {
  Duration _duration = Duration.zero;
  var _position = Duration.zero;

  final timeStampStyle = const TextStyle(
    fontSize: 12,
    color: Colors.white54,
  );

  @override
  void initState() {
    super.initState();

    subscribe(audioHandler.player.positionStream.listen((position) {
      setState(() => _position = position);
    }));

    subscribe(audioHandler.mediaItem.listen((mediaItem) {
      if (mediaItem != null && mediaItem.duration != null) {
        setState(() => _duration = mediaItem.duration ?? Duration.zero);
      }
    }));
  }

  @override
  void dispose() {
    unsubscribeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_duration == Duration.zero) return SizedBox.shrink();

    return Container(
      width: double.infinity,
      alignment: Alignment.centerLeft,
      height: 1.0,
      color: Colors.white12,
      child: FractionallySizedBox(
        widthFactor: _position.inSeconds / _duration.inSeconds,
        child: Container(color: Colors.white),
      ),
    );
  }
}

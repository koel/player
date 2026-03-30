import 'package:app/constants/constants.dart';
import 'package:app/enums.dart';
import 'package:app/main.dart';
import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/models/playable.dart';
import 'package:app/providers/providers.dart';
import 'package:app/router.dart';
import 'package:app/ui/screens/radio_now_playing.dart';
import 'package:app/ui/widgets/now_playing_page_route.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  void _openRadioNowPlaying(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      NowPlayingPageRoute(
          builder: (_) => const RadioNowPlayingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RadioPlayerProvider>(
      builder: (context, radioPlayer, _) {
        if (radioPlayer.active) {
          return _buildRadioMiniPlayer(radioPlayer);
        }

        return _buildQueueMiniPlayer();
      },
    );
  }

  Widget _buildShell({required Widget content, Widget? progressBar}) {
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
                  child: content,
                ),
                if (progressBar != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: progressBar,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _radioDefaultIcon() {
    return Container(
      width: 36,
      height: 36,
      color: AppColors.highlight.withOpacity(0.3),
      child: const Icon(
        CupertinoIcons.antenna_radiowaves_left_right,
        size: 18,
        color: Colors.white,
      ),
    );
  }

  Widget _buildRadioMiniPlayer(RadioPlayerProvider radioPlayer) {
    final station = radioPlayer.currentStation!;

    return _buildShell(
      content: InkWell(
        onTap: () => _openRadioNowPlaying(context),
        child: Row(
          children: <Widget>[
            // Station logo
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: station.logo != null
                  ? CachedNetworkImage(
                      imageUrl: station.logo!,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _radioDefaultIcon(),
                    )
                  : _radioDefaultIcon(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MarqueeText(
                      text: radioPlayer.streamTitle ?? station.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (radioPlayer.loading)
                      const Text(
                        'Connecting…',
                        style: TextStyle(fontSize: 12, color: Colors.white54),
                      )
                    else if (radioPlayer.streamTitle != null)
                      Text(
                        station.name,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.white54),
                      ),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: radioPlayer.togglePlayPause,
              icon: Icon(
                radioPlayer.playing
                    ? CupertinoIcons.pause_fill
                    : CupertinoIcons.play_fill,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueMiniPlayer() {
    final playable = _playable;
    final state = _state;

    if (playable == null || state == null) return SizedBox.shrink();

    late final bool isLoading;

    if ((state.processingState == AudioProcessingState.buffering ||
            state.processingState == AudioProcessingState.loading) &&
        state.playing) {
      isLoading = true;
    } else {
      isLoading = false;
    }

    return _buildShell(
      content: InkWell(
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
                                PlayableThumbnail.borderRadiusForSize(
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
                        child: SpinKitThreeBounce(
                            color: AppColors.white, size: 16),
                      ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    child: MarqueeText(
                      text: playable.title,
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
      progressBar: const MiniPlayerProgressBar(),
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
        setState(() => _duration = mediaItem.duration!);
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
    if (_duration.inMilliseconds == 0) return SizedBox.shrink();

    final progress = (_position.inMilliseconds / _duration.inMilliseconds)
        .clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      alignment: Alignment.centerLeft,
      height: 1.0,
      color: Colors.white12,
      child: FractionallySizedBox(
        widthFactor: progress,
        child: Container(color: Colors.white),
      ),
    );
  }
}

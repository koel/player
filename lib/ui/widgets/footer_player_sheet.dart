import 'package:app/constants/constants.dart';
import 'package:app/main.dart';
import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/router.dart';
import 'package:app/ui/widgets/frosted_glass_background.dart';
import 'package:app/ui/widgets/song_thumbnail.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

class FooterPlayerSheet extends StatefulWidget {
  static Key pauseButtonKey = UniqueKey();
  static Key nextButtonKey = UniqueKey();

  final AppRouter router;

  const FooterPlayerSheet({
    Key? key,
    this.router = const AppRouter(),
  }) : super(key: key);

  @override
  _FooterPlayerSheetState createState() => _FooterPlayerSheetState();
}

class _FooterPlayerSheetState extends State<FooterPlayerSheet>
    with StreamSubscriber {
  late SongProvider _songProvider;
  PlaybackState? _state;
  Song? _song;

  @override
  void initState() {
    super.initState();
    _songProvider = context.read();

    subscribe(audioHandler.playbackState.listen((PlaybackState value) {
      setState(() => _state = value);
    }));

    subscribe(audioHandler.mediaItem.listen((MediaItem? value) {
      if (value != null) setState(() => _song = _songProvider.byId(value.id));
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
    final state = _state;

    if (song == null || state == null) return SizedBox.shrink();

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

    return FrostedGlassBackground(
      sigma: 10.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.white.withOpacity(0.1),
              width: .5,
            ),
            bottom: BorderSide(
              color: AppColors.white.withOpacity(0.1),
              width: .5,
            ),
          ),
        ),
        child: InkWell(
          onTap: () => widget.router.openNowPlayingScreen(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Stack(
                children: [
                  Hero(
                    tag: 'hero-now-playing-thumbnail',
                    child: SongThumbnail(song: song),
                  ),
                  if (isLoading)
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(
                            Radius.circular(8),
                          ),
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  if (isLoading)
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: statusIndicator,
                    ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        song.title,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artistName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white60),
                      )
                    ],
                  ),
                ),
              ),
              Row(
                children: <Widget>[
                  IconButton(
                    key: FooterPlayerSheet.pauseButtonKey,
                    onPressed: audioHandler.playOrPause,
                    icon: Icon(
                      state.playing
                          ? CupertinoIcons.pause_fill
                          : CupertinoIcons.play_fill,
                      size: 24,
                    ),
                  ),
                  IconButton(
                    key: FooterPlayerSheet.nextButtonKey,
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
        ),
      ),
    );
  }
}

import 'dart:ui';

import 'package:app/extensions/assets_audio_player.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/audio_provider.dart';
import 'package:app/providers/song_provider.dart';
import 'package:app/ui/screens/info_sheet.dart';
import 'package:app/ui/screens/queue.dart';
import 'package:app/ui/screens/song_action_sheet.dart';
import 'package:app/ui/widgets/now_playing/audio_controls.dart';
import 'package:app/ui/widgets/now_playing/loop_mode_button.dart';
import 'package:app/ui/widgets/now_playing/progress_bar.dart';
import 'package:app/ui/widgets/now_playing/song_info.dart';
import 'package:app/ui/widgets/now_playing/volume_slider.dart';
import 'package:app/ui/widgets/song_cache_icon.dart';
import 'package:app/ui/widgets/song_thumbnail.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AudioProvider audio = context.watch();
    final SongProvider songProvider = context.watch();

    Color bottomIconColor = Colors.white54;

    return StreamBuilder<Playing?>(
      stream: audio.player.current,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        String? songId = audio.player.songId;
        if (songId == null) return const SizedBox.shrink();
        Song song = songProvider.byId(songId);

        final Widget frostGlassBackground = SizedBox(
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

        final Widget thumbnail = Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Hero(
            tag: 'hero-now-playing-thumbnail',
            child: SongThumbnail(song: song, size: ThumbnailSize.xl),
          ),
        );

        final Widget infoPane = Column(
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
                      showActionSheet(context: context, song: song),
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
            Container(color: Colors.black),
            frostGlassBackground,
            Container(color: Colors.black54),
            Padding(
              padding: const EdgeInsets.all(24),
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
                          const LoopModeButton(),
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
          ],
        );
      },
    );
  }
}

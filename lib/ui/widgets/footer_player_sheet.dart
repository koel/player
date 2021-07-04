import 'dart:ui';

import 'package:app/models/song.dart';
import 'package:app/providers/audio_player_provider.dart';
import 'package:app/providers/song_provider.dart';
import 'package:app/ui/screens/now_playing.dart';
import 'package:app/ui/widgets/player/playing_controls.dart';
import 'package:app/ui/widgets/song_thumbnail.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FooterPlayerSheet extends StatefulWidget {
  @override
  _FooterPlayerSheetState createState() => _FooterPlayerSheetState();
}

class _FooterPlayerSheetState extends State<FooterPlayerSheet> {
  late AudioPlayerProvider audio;
  late SongProvider songProvider;

  @override
  void initState() {
    super.initState();
    audio = context.read<AudioPlayerProvider>();
  }

  @override
  Widget build(BuildContext context) {
    songProvider = context.watch<SongProvider>();

    return StreamBuilder<Playing?>(
      stream: audio.player.current,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        String? songId = snapshot.data?.audio.audio.metas.extra?['songId'];
        if (songId == null) return SizedBox.shrink();

        Song current = songProvider.byId(songId);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRect(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white, width: 0.5),
                  ),
                ),
                child: BackdropFilter(
                  filter: new ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                  child: InkWell(
                    onTap: () => openNowPlayingScreen(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Hero(
                          tag: 'hero-now-playing-thumbnail',
                          child: SongThumbnail(
                            song: songProvider.byId(songId),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  current.title,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  current.artist.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .caption
                                        ?.color,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        audio.player.builderLoopMode(
                          builder: (context, loopMode) {
                            return PlayerBuilder.isPlaying(
                              player: audio.player,
                              builder: (context, isPlaying) {
                                return PlayingControls(
                                  loopMode: loopMode,
                                  isPlaying: isPlaying,
                                  isPlaylist: true,
                                  onStop: () {
                                    audio.player.stop();
                                  },
                                  toggleLoop: () {
                                    audio.player.toggleLoop();
                                  },
                                  onPlay: () {
                                    audio.player.playOrPause();
                                  },
                                  onNext: () {
                                    audio.player.next();
                                  },
                                  onPrevious: () {
                                    audio.player.previous();
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

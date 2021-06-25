import 'dart:async';
import 'dart:ui';

import 'package:app/providers/audio_player_provider.dart';
import 'package:app/providers/song_provider.dart';
import 'package:app/ui/screens/queue.dart';
import 'package:app/ui/widgets/player/playing_controls.dart';
import 'package:app/ui/widgets/song_thumbnail.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:audio_service/audio_service.dart';
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
  }

  Future<void> initAudio() async {
    songProvider = Provider.of<SongProvider>(context);
    audio = Provider.of<AudioPlayerProvider>(context);
    await audio.init();
  }

  @override
  Widget build(BuildContext context) {
    initAudio();

    return ClipRect(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: BackdropFilter(
          filter: new ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
          child: InkWell(
            onTap: () => _openQueue(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                audio.player.builderCurrent(
                  builder: (BuildContext context, Playing playing) {
                    String? songId = playing.audio.audio.metas.extra?['songId'];
                    return songId == null
                        ? SizedBox()
                        : SongThumbnail(song: songProvider.byId(songId));
                  },
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
                        });
                  },
                ),

                // SongThumbnail(song: song),
                // Expanded(
                //   child: Padding(
                //     padding: EdgeInsets.symmetric(horizontal: 16),
                //     child: Column(
                //       mainAxisSize: MainAxisSize.min,
                //       crossAxisAlignment: CrossAxisAlignment.start,
                //       children: [
                //         Text(
                //           snapshot.data!.title,
                //           overflow: TextOverflow.ellipsis,
                //         ),
                //         SizedBox(height: 4),
                //         Text(
                //           snapshot.data!.artist!,
                //           overflow: TextOverflow.ellipsis,
                //           style: TextStyle(
                //             color:
                //                 Theme.of(context).textTheme.caption?.color,
                //           ),
                //         )
                //       ],
                //     ),
                //   ),
                // ),
                // StreamBuilder<bool>(
                //   stream: AudioService.playbackStateStream
                //       .map((state) => state.playing)
                //       .distinct(),
                //   builder: (context, snapshot) {
                //     final playing = snapshot.data ?? false;
                //     return playing ? pauseButton() : playButton();
                //   },
                // ),
                // nextButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconButton playButton() => IconButton(
        icon: Icon(Icons.play_arrow),
        iconSize: 32.0,
        onPressed: AudioService.play,
      );

  IconButton pauseButton() => IconButton(
        icon: Icon(Icons.pause),
        iconSize: 32.0,
        onPressed: AudioService.pause,
      );

  IconButton nextButton() => IconButton(
        icon: Icon(Icons.skip_next),
        iconSize: 32.0,
        onPressed: AudioService.skipToNext,
      );

  Future<void> _openQueue(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      builder: (BuildContext context) {
        var padding = MediaQuery.of(context).padding;
        return Container(
          height: MediaQuery.of(context).size.height -
              padding.top -
              padding.bottom -
              16,
          padding: EdgeInsets.all(16),
          child: QueueScreen(),
        );
      },
    );
  }
}

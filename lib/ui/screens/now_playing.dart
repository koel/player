import 'dart:async';
import 'dart:ui';

import 'package:app/extensions/assets_audio_player.dart';
import 'package:app/extensions/duration.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/audio_player_provider.dart';
import 'package:app/providers/song_provider.dart';
import 'package:app/ui/screens/info.dart';
import 'package:app/ui/screens/queue.dart';
import 'package:app/ui/screens/song_action_sheet.dart';
import 'package:app/ui/widgets/song_cache_icon.dart';
import 'package:app/ui/widgets/song_thumbnail.dart';
import 'package:app/utils/preferences.dart' as preferences;
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NowPlayingScreen extends StatefulWidget {
  @override
  _NowPlayingScreenState createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  late AudioPlayerProvider audio;
  late SongProvider songProvider;
  Duration _duration = Duration();
  Duration _position = Duration();
  late double _volume;
  late LoopMode _loopMode;
  List<StreamSubscription> _subscriptions = [];

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();

    songProvider = context.read<SongProvider>();
    audio = context.read<AudioPlayerProvider>();

    tryLoadAudioPreferences();

    _subscriptions.add(audio.player.currentPosition.listen((position) {
      setState(() => _position = position);
    }));

    _subscriptions.add(audio.player.current.listen((Playing? playing) {
      if (playing == null) return;

      setState(() => _duration = playing.audio.duration);

      if (audio.player.songId == null) return;
    }));

    _subscriptions.add(audio.player.volume.listen((volume) {
      setState(() => _volume = volume);
    }));

    _subscriptions.add(audio.player.loopMode.listen((loopMode) {
      setState(() => _loopMode = loopMode);
    }));
  }

  @override
  void dispose() {
    _subscriptions.forEach((element) => element.cancel());
    super.dispose();
  }

  Widget hero(Song song) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Hero(
        tag: 'hero-now-playing-thumbnail',
        child: SongThumbnail(song: song, size: ThumbnailSize.xl),
      ),
    );
  }

  Widget songInfo(Song song) {
    double mainFontSize = Theme.of(context).textTheme.headline6?.fontSize ?? 20;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          song.title,
          style: TextStyle(
            fontSize: mainFontSize,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 4),
        Text(
          song.artist.name,
          style: TextStyle(
            color: Theme.of(context).textTheme.caption?.color,
            fontSize: mainFontSize - 2,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget progress() {
    TextStyle timeStampStyle = TextStyle(
      fontSize: 12,
      color: Colors.white.withOpacity(.5),
    );

    return Column(
      children: <Widget>[
        Slider(
          value: _position.inSeconds.toDouble(),
          min: 0.0,
          max: _duration.inSeconds.toDouble(),
          onChanged: (double value) {
            audio.player.seek(Duration(seconds: value.toInt()));
          },
        ),
        Container(
          // move the timestamps up a bit
          transform: Matrix4.translationValues(0.0, -4.0, 0.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(_position.toMs(), style: timeStampStyle),
              Text('-' + (_duration - _position).toMs(), style: timeStampStyle),
            ],
          ),
        ),
      ],
    );
  }

  Widget audioControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          onPressed: () {
            if (_position.inSeconds > 5) {
              audio.player.restart();
            } else {
              audio.player.previous();
            }
          },
          icon: Icon(CupertinoIcons.backward_fill),
          iconSize: 48,
        ),
        PlayerBuilder.isPlaying(
          player: audio.player,
          builder: (context, isPlaying) {
            return IconButton(
              onPressed: () => audio.player.playOrPause(),
              icon: Icon(
                isPlaying
                    ? CupertinoIcons.pause_solid
                    : CupertinoIcons.play_fill,
              ),
              iconSize: 64,
            );
          },
        ),
        IconButton(
          onPressed: () => audio.player.next(),
          icon: const Icon(CupertinoIcons.forward_fill),
          iconSize: 48,
        ),
      ],
    );
  }

  Widget volumeSlider() {
    return Row(
      children: <Widget>[
        Icon(
          CupertinoIcons.volume_mute,
          size: 16,
          color: Colors.white.withOpacity(.5),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SliderTheme(
              data: Theme.of(context).sliderTheme.copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                  ),
              child: Slider(
                min: 0.0,
                max: 1.0,
                value: _volume,
                onChanged: (value) {
                  audio.player.setVolume(value);
                  preferences.setVolume(value);
                },
              ),
            ),
          ),
        ),
        Icon(
          CupertinoIcons.volume_up,
          size: 16,
          color: Colors.white.withOpacity(.5),
        ),
      ],
    );
  }

  Widget loopModeButton() {
    return IconButton(
      color: _loopMode == LoopMode.none
          ? Colors.white.withOpacity(.2)
          : Colors.white,
      onPressed: () async {
        late LoopMode newMode;
        if (_loopMode == LoopMode.none)
          newMode = LoopMode.playlist;
        else if (_loopMode == LoopMode.playlist)
          newMode = LoopMode.single;
        else
          newMode = LoopMode.none;
        audio.player.setLoopMode(newMode);
        await preferences.setLoopMode(newMode);
        setState(() => _loopMode = newMode);
      },
      icon: Icon(
        _loopMode == LoopMode.single
            ? CupertinoIcons.repeat_1
            : CupertinoIcons.repeat,
      ),
    );
  }

  Widget extraControls(Song song) {
    Color iconColor = Colors.white.withOpacity(.5);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        loopModeButton(),
        IconButton(
          onPressed: () => showInfoSheet(context, song: song),
          icon: Icon(CupertinoIcons.text_quote, color: iconColor),
        ),
        IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => QueueScreen()),
            );
          },
          icon: Icon(CupertinoIcons.list_number, color: iconColor),
        ),
      ],
    );
  }

  Widget actionButton(Song song) {
    return IconButton(
      onPressed: () => showActionSheet(context: context, song: song),
      icon: const Icon(CupertinoIcons.ellipsis),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Playing?>(
      stream: audio.player.current,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        String? songId = audio.player.songId;
        if (songId == null) return const SizedBox.shrink();
        Song song = songProvider.byId(songId);

        return Stack(
          children: <Widget>[
            Container(color: Colors.black),
            SizedBox(
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
            ),
            Container(color: Colors.black.withOpacity(.7)),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  hero(song),
                  Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Expanded(child: songInfo(song)),
                          SongCacheIcon(song: song),
                          actionButton(song),
                        ],
                      ),
                      const SizedBox(height: 8),
                      progress(),
                    ],
                  ),
                  audioControls(),
                  Column(
                    children: <Widget>[
                      volumeSlider(),
                      extraControls(song),
                    ],
                  )
                ],
              ),
            )
          ],
        );
      },
    );
  }

  Future<void> tryLoadAudioPreferences() async {
    LoopMode mode = await preferences.loopMode;
    double volume = await preferences.volume;

    setState(() {
      _loopMode = mode;
      _volume = volume;
    });
  }
}

Future<void> openNowPlayingScreen(BuildContext context) async {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return Container(
        height: MediaQuery.of(context).size.height,
        child: NowPlayingScreen(),
      );
    },
  );
}

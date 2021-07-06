import 'dart:async';

import 'package:app/extensions/assets_audio_player.dart';
import 'package:app/extensions/duration.dart';
import 'package:app/providers/audio_player_provider.dart';
import 'package:app/providers/song_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProgressBar extends StatefulWidget {
  const ProgressBar({
    Key? key,
  }) : super(key: key);

  _ProgressBarState createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar> {
  late final AudioPlayerProvider audio;
  late final SongProvider songProvider;

  List<StreamSubscription> _subscriptions = [];

  Duration _duration = Duration();
  Duration _position = Duration();

  TextStyle timeStampStyle = TextStyle(
    fontSize: 12,
    color: Colors.white.withOpacity(.5),
  );

  @override
  void initState() {
    super.initState();
    audio = context.read();
    songProvider = context.read();

    setState(() {
      _duration = Duration(
        seconds: songProvider.byId(audio.player.songId!).length.toInt(),
      );
    });

    _subscriptions.add(audio.player.currentPosition.listen((position) {
      setState(() => _position = position);
    }));
  }

  @override
  void dispose() {
    _subscriptions.forEach((sub) => sub.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
}

import 'package:app/extensions/assets_audio_player.dart';
import 'package:app/extensions/duration.dart';
import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/providers/audio_provider.dart';
import 'package:app/providers/song_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProgressBar extends StatefulWidget {
  const ProgressBar({Key? key}) : super(key: key);

  _ProgressBarState createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar> with StreamSubscriber {
  late final AudioProvider audio;
  late final SongProvider songProvider;

  late Duration _duration, _position;

  TextStyle timeStampStyle = const TextStyle(
    fontSize: 12,
    color: Colors.white54,
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

    subscribe(audio.player.currentPosition.listen((position) {
      setState(() => _position = position);
    }));
  }

  @override
  void dispose() {
    unsubscribeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Slider(
          value: _position.inSeconds.toDouble(),
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

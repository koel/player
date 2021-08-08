import 'package:app/extensions/duration.dart';
import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/audio_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProgressBar extends StatefulWidget {
  final Song song;

  const ProgressBar({Key? key, required this.song}) : super(key: key);

  _ProgressBarState createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar> with StreamSubscriber {
  late final AudioProvider audio;
  late Duration _duration, _position;

  TextStyle timeStampStyle = const TextStyle(
    fontSize: 12,
    color: Colors.white54,
  );

  @override
  void initState() {
    super.initState();
    audio = context.read();

    setState(() => _duration = Duration(seconds: widget.song.length.toInt()));

    subscribe(audio.player.currentPosition.listen((position) {
      setState(() => _position = position);
    }));
  }

  /// Since this widget is rendered inside NowPlayingScreen, change to current
  /// song in the parent will not trigger initState() and as a result not
  /// refresh the progress bar's values.
  /// For that, we hook into didUpdateWidget().
  /// See https://stackoverflow.com/questions/54759920/flutter-why-is-child-widgets-initstate-is-not-called-on-every-rebuild-of-pa.
  @override
  void didUpdateWidget(covariant ProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() => _duration = Duration(seconds: widget.song.length.toInt()));
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

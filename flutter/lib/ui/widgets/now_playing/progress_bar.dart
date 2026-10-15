import 'package:app/extensions/extensions.dart';
import 'package:app/main.dart';
import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:flutter/material.dart';

class ProgressBar extends StatefulWidget {
  final Playable playable;

  const ProgressBar({Key? key, required this.playable}) : super(key: key);

  _ProgressBarState createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar> with StreamSubscriber {
  late Duration _duration;
  var _position = Duration.zero;
  var _shouldAutoUpdatePosition = true;

  final timeStampStyle = const TextStyle(
    fontSize: 12,
    color: Colors.white54,
  );

  @override
  void initState() {
    super.initState();

    setState(
        () => _duration = Duration(seconds: widget.playable.length.toInt()));

    subscribe(audioHandler.player.positionStream.listen((position) {
      if (_shouldAutoUpdatePosition) setState(() => _position = position);
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
    setState(
        () => _duration = Duration(seconds: widget.playable.length.toInt()));
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
            setState(() => _position = Duration(seconds: value.toInt()));
          },
          onChangeStart: (_) => _shouldAutoUpdatePosition = false,
          onChangeEnd: (double value) {
            _shouldAutoUpdatePosition = true;
            audioHandler.player.seek(Duration(seconds: value.toInt()));
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

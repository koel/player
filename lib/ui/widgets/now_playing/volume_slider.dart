import 'package:app/providers/audio_provider.dart';
import 'package:app/utils/preferences.dart' as preferences;
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VolumeSlider extends StatefulWidget {
  const VolumeSlider({Key? key}) : super(key: key);

  @override
  _VolumeSliderState createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<VolumeSlider> {
  double _volume = .7;
  late AudioProvider audio;

  @override
  void initState() {
    super.initState();
    audio = context.read();

    setState(() => _volume = preferences.volume);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(
          CupertinoIcons.volume_mute,
          size: 16,
          color: Colors.white54,
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
                  setState(() => _volume = value);
                  audio.player.setVolume(value);
                  preferences.volume = value;
                },
              ),
            ),
          ),
        ),
        Icon(
          CupertinoIcons.volume_up,
          size: 16,
          color: Colors.white54,
        ),
      ],
    );
  }
}

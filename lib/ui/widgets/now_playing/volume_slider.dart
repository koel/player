import 'package:app/main.dart';
import 'package:app/utils/preferences.dart' as preferences;
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

class VolumeSlider extends StatefulWidget {
  const VolumeSlider({Key? key}) : super(key: key);

  @override
  _VolumeSliderState createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<VolumeSlider> {
  var _volume = 0.7;

  @override
  void initState() {
    super.initState();
    setState(() => _volume = preferences.volume);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Icon(
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
                  audioHandler.setVolume(value);
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

import 'package:app/models/models.dart';
import 'package:app/ui/widgets/marquee_text.dart';
import 'package:flutter/material.dart';

class PlayableInfo extends StatelessWidget {
  final Playable playable;

  const PlayableInfo({Key? key, required this.playable}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    late final String subtitle;

    if (playable is Song) {
      subtitle = (playable as Song).artistName;
    } else if (playable is Episode) {
      subtitle = (playable as Episode).podcastTitle;
    } else {
      subtitle = '';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        MarqueeText(
          text: playable.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        MarqueeText(
          text: subtitle,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}

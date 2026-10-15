import 'package:app/models/models.dart';
import 'package:app/providers/playable_provider.dart';
import 'package:app/ui/widgets/marquee_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlayableInfo extends StatelessWidget {
  final Playable playable;

  const PlayableInfo({Key? key, required this.playable}) : super(key: key);

  String get _subtitle {
    if (playable is Song) return (playable as Song).artistName;
    if (playable is Episode) return (playable as Episode).podcastTitle;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayableProvider>(
      builder: (_, __, ___) => Column(
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
            text: _subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:app/models/models.dart';
import 'package:app/ui/screens/info_sheet/info_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class LyricsPane extends StatelessWidget {
  final Song song;

  LyricsPane({Key? key, required this.song}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return song.lyrics.isEmpty
        ? const Padding(
            padding: const EdgeInsets.only(top: 16),
            child: const Text(
              'No lyrics available.',
              style: const TextStyle(color: Colors.white54),
            ),
          )
        : Padding(
            padding: EdgeInsets.only(top: 4.0),
            child: InfoHtml(
              content:
                  song.lyrics.replaceAll('\n', '<br>').replaceAll('\r', '<br>'),
              style: Style(fontSize: FontSize.larger),
            ),
          );
  }
}

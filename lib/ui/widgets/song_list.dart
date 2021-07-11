import 'package:app/constants/dimensions.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/audio_player_provider.dart';
import 'package:app/ui/widgets/buttons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum SongListContext {
  queue,
  allSongs,
  album,
  artist,
  playlist,
  favorites,
  other,
}

class SongListButtons extends StatelessWidget {
  final List<Song> songs;

  const SongListButtons({Key? key, required this.songs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    AudioPlayerProvider audio = context.read();
    return Container(
      padding: const EdgeInsets.all(AppDimensions.horizontalPadding),
      child: Row(
        children: <Widget>[
          FullWidthPrimaryIconButton(
            icon: CupertinoIcons.play_fill,
            label: 'Play All',
            onPressed: () async => await audio.replaceQueue(songs),
          ),
          const SizedBox(width: 12),
          FullWidthPrimaryIconButton(
            icon: CupertinoIcons.shuffle,
            label: 'Shuffle All',
            onPressed: () async =>
                await audio.replaceQueue(songs, shuffle: true),
          ),
        ],
      ),
    );
  }
}

import 'package:app/constants/dimensions.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/audio_provider.dart';
import 'package:app/ui/widgets/full_width_primary_icon_button.dart';
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
  static final Key playAllButtonKey = UniqueKey();
  static final Key shuffleAllButtonKey = UniqueKey();

  final List<Song> songs;

  const SongListButtons({Key? key, required this.songs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    AudioProvider audio = context.read();
    return Container(
      padding: const EdgeInsets.all(AppDimensions.horizontalPadding),
      child: Row(
        children: <Widget>[
          FullWidthPrimaryIconButton(
            key: SongListButtons.playAllButtonKey,
            icon: CupertinoIcons.play_fill,
            label: 'Play All',
            onPressed: () async => await audio.replaceQueue(songs),
          ),
          const SizedBox(width: 12),
          FullWidthPrimaryIconButton(
            key: SongListButtons.shuffleAllButtonKey,
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

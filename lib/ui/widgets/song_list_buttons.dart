import 'package:app/constants/constants.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/widgets/full_width_primary_icon_button.dart';
import 'package:flutter/cupertino.dart';
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

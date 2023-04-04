import 'package:app/constants/constants.dart';
import 'package:app/models/models.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';

class SliverSongList extends StatelessWidget {
  final List<Song> songs;
  final SongListContext listContext;
  final Widget dismissIcon;
  final Function(Song song)? onDismissed;

  SliverSongList({
    Key? key,
    required this.songs,
    this.listContext = SongListContext.other,
    this.onDismissed,
    this.dismissIcon = const Icon(CupertinoIcons.delete),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, int index) {
          return onDismissed == null
              ? SongRow(song: songs[index], listContext: listContext)
              : Dismissible(
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => onDismissed?.call(songs[index]),
                  background: Container(
                    alignment: AlignmentDirectional.centerEnd,
                    color: AppColors.highlightAccent,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 28),
                      child: dismissIcon,
                    ),
                  ),
                  key: ValueKey(songs[index]),
                  child: SongRow(song: songs[index], listContext: listContext),
                );
        },
        childCount: songs.length,
      ),
    );
  }
}

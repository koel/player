import 'package:app/models/song.dart';
import 'package:app/providers/cache_provider.dart';
import 'package:app/ui/widgets/app_bar.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/song_list_buttons.dart';
import 'package:app/ui/widgets/song_row.dart';
import 'package:app/ui/widgets/sortable_song_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide AppBar;
import 'package:provider/provider.dart';

class DownloadedScreen extends StatefulWidget {
  static const routeName = '/downloaded';

  const DownloadedScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DownloadedScreenState();
}

OrderBy _currentSortOrder = OrderBy.title;

class _DownloadedScreenState extends State<DownloadedScreen> {
  OrderBy _sortOrder = _currentSortOrder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<CacheProvider>(
        builder: (_, provider, __) {
          if (provider.songs.length == 0) {
            return Center(
              child: Text('No downloaded songs available.'),
            );
          }

          List<Song> songs = sortSongs(provider.songs, orderBy: _sortOrder);

          return CustomScrollView(
            slivers: <Widget>[
              AppBar(
                headingText: 'Downloaded',
                coverImage: CoverImageStack(songs: songs),
                actions: [
                  SortButton(
                    options: {
                      OrderBy.artist: 'Artist',
                      OrderBy.title: 'Song title',
                      OrderBy.recentlyAdded: 'Recently added',
                    },
                    currentOrder: _sortOrder,
                    onActionSheetActionPressed: (OrderBy order) {
                      _currentSortOrder = order;
                      setState(() => _sortOrder = order);
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(child: SongListButtons(songs: songs)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, int index) {
                    return Dismissible(
                      direction: DismissDirection.endToStart,
                      onDismissed: (DismissDirection direction) =>
                          provider.remove(song: songs[index]),
                      background: Container(
                        alignment: AlignmentDirectional.centerEnd,
                        color: Colors.red,
                        child: const Padding(
                          padding: EdgeInsets.only(right: 28),
                          child: Icon(CupertinoIcons.delete),
                        ),
                      ),
                      key: ValueKey(songs[index]),
                      child: SongRow(song: songs[index]),
                    );
                  },
                  childCount: songs.length,
                ),
              ),
              const SliverToBoxAdapter(child: BottomSpace()),
            ],
          );
        },
      ),
    );
  }
}

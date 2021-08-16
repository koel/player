import 'package:app/constants/dimensions.dart';
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
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.horizontalPadding,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'No downloaded songs',
                      style: Theme.of(context).textTheme.headline5,
                    ),
                    const SizedBox(height: 16.0),
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(color: Colors.white54),
                        children: <InlineSpan>[
                          TextSpan(text: 'Tap the'),
                          WidgetSpan(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5.0),
                              child: Icon(
                                CupertinoIcons.cloud_download_fill,
                                size: 16.0,
                              ),
                            ),
                          ),
                          TextSpan(
                            text: 'icon next to a song to download it for '
                                'offline playback.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
              const BottomSpace(),
            ],
          );
        },
      ),
    );
  }
}

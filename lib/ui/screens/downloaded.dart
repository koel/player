import 'package:app/constants/constants.dart';
import 'package:app/enums.dart';
import 'package:app/extensions/extensions.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/widgets/app_bar.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/song_list_header.dart';
import 'package:app/ui/widgets/song_row.dart';
import 'package:app/ui/widgets/song_list_sort_button.dart';
import 'package:app/values/values.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide AppBar;
import 'package:provider/provider.dart';

class DownloadedScreen extends StatefulWidget {
  static const routeName = '/downloaded';

  const DownloadedScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DownloadedScreenState();
}

class _DownloadedScreenState extends State<DownloadedScreen> {
  String _searchQuery = '';
  CoverImageStack _cover = CoverImageStack(songs: []);

  @override
  Widget build(BuildContext context) {
    final AppStateProvider appState = context.read();
    SongSortConfig sortConfig = appState.get('downloaded.sort') ??
        SongSortConfig(
          field: 'title',
          order: SortOrder.asc,
        );

    return Scaffold(
      body: Consumer<DownloadProvider>(
        builder: (_, provider, __) {
          if (provider.songs.isEmpty) {
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
                      style: Theme.of(context).textTheme.headlineSmall,
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

          if (_cover.isEmpty) {
            _cover = CoverImageStack(songs: provider.songs);
          }

          final displayedSongs =
              provider.songs.$sort(sortConfig).$filter(_searchQuery);

          return CustomScrollView(
            slivers: <Widget>[
              AppBar(
                headingText: 'Downloaded',
                coverImage: _cover,
                actions: [
                  SortButton(
                    fields: ['title', 'artist_name', 'created_at'],
                    currentField: sortConfig.field,
                    currentOrder: sortConfig.order,
                    onMenuItemSelected: (_sortConfig) {
                      setState(() => sortConfig = _sortConfig);
                      appState.set('downloaded.sort', _sortConfig);
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: SongListHeader(
                  songs: displayedSongs,
                  onSearchQueryChanged: (String query) {
                    setState(() => _searchQuery = query);
                  },
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, int index) {
                    return Dismissible(
                      direction: DismissDirection.endToStart,
                      onDismissed: (DismissDirection direction) =>
                          provider.remove(song: displayedSongs[index]),
                      background: Container(
                        alignment: AlignmentDirectional.centerEnd,
                        color: Colors.red,
                        child: const Padding(
                          padding: EdgeInsets.only(right: 28),
                          child: Icon(CupertinoIcons.delete),
                        ),
                      ),
                      key: ValueKey(displayedSongs[index]),
                      child: SongRow(
                        song: displayedSongs[index],
                        listContext: SongListContext.downloads,
                      ),
                    );
                  },
                  childCount: displayedSongs.length,
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

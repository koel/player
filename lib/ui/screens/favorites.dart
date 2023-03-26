import 'package:app/constants/constants.dart';
import 'package:app/enums.dart';
import 'package:app/extensions/extensions.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/widgets/app_bar.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/pull_to_refresh.dart';
import 'package:app/ui/widgets/song_list_header.dart';
import 'package:app/ui/widgets/song_row.dart';
import 'package:app/ui/widgets/song_list_sort_button.dart';
import 'package:app/ui/widgets/spinner.dart';
import 'package:app/values/values.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide AppBar;
import 'package:provider/provider.dart';

class FavoritesScreen extends StatefulWidget {
  static const routeName = '/favorites';

  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _loading = false;
  String _searchQuery = '';
  CoverImageStack cover = CoverImageStack(songs: []);

  @override
  void initState() {
    super.initState();
    makeRequest();
  }

  Future<void> makeRequest({bool forceRefresh = false}) async {
    _loading = true;
    await context.read<FavoriteProvider>().fetch(forceRefresh: forceRefresh);
    _loading = false;
  }

  @override
  Widget build(BuildContext context) {
    final AppStateProvider appState = context.read();
    SongSortConfig sortConfig = appState.get('favorites.sort') ??
        SongSortConfig(field: 'title', order: SortOrder.asc);

    var emptyWidget = SliverFillRemaining(
      hasScrollBody: false,
      fillOverscroll: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.horizontalPadding,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                CupertinoIcons.heart,
                size: 56.0,
                color: Colors.grey,
              ),
              const SizedBox(height: 16.0),
              Text(
                'No favorites',
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
                          CupertinoIcons.heart_solid,
                          size: 16.0,
                        ),
                      ),
                    ),
                    TextSpan(
                      text: 'icon in a song’s menu to mark it as '
                          'favorite.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      body: Consumer<FavoriteProvider>(
        builder: (_, provider, __) {
          if (provider.songs.isEmpty && _loading) {
            return const Center(child: const Spinner());
          }

          if (cover.isEmpty) {
            cover = CoverImageStack(songs: provider.songs);
          }

          final songs = provider.songs.$sort(sortConfig).$filter(_searchQuery);

          return PullToRefresh(
            onRefresh: () {
              return _loading
                  ? Future(() => null)
                  : makeRequest(forceRefresh: true);
            },
            child: CustomScrollView(
              slivers: provider.songs.isEmpty
                  ? <Widget>[emptyWidget]
                  : <Widget>[
                      AppBar(
                        headingText: 'Favorites',
                        coverImage: cover,
                        actions: [
                          SortButton(
                            fields: ['title', 'artist_name', 'created_at'],
                            currentField: sortConfig.field,
                            currentOrder: sortConfig.order,
                            onMenuItemSelected: (_sortConfig) {
                              setState(() => sortConfig = _sortConfig);
                              appState.set('favorites.sort', sortConfig);
                            },
                          ),
                        ],
                      ),
                      SliverToBoxAdapter(
                        child: SongListHeader(
                          songs: songs,
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
                                  provider.unlike(song: songs[index]),
                              background: Container(
                                alignment: AlignmentDirectional.centerEnd,
                                color: Colors.red,
                                child: const Padding(
                                  padding: EdgeInsets.only(right: 28),
                                  child: Icon(CupertinoIcons.heart_slash),
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
            ),
          );
        },
      ),
    );
  }
}

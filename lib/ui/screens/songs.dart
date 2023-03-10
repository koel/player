import 'package:app/enums.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/widgets/app_bar.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/song_list_buttons.dart';
import 'package:app/ui/widgets/song_row.dart';
import 'package:app/ui/widgets/sortable_song_list.dart';
import 'package:app/ui/widgets/spinner.dart';
import 'package:flutter/material.dart' hide AppBar;
import 'package:provider/provider.dart';

// Keep track of the sort orders between revisits
SortField _currentSortOrder = SortField.title;

class SongsScreen extends StatefulWidget {
  static const routeName = '/songs';

  const SongsScreen({Key? key}) : super(key: key);

  @override
  _SongsScreenState createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  SortField _sortField = _currentSortOrder;

  late SongProvider _songProvider;
  late AppStateProvider _appState;
  late SongPaginationConfig _paginationConfig;
  late ScrollController _scrollController;
  late double _currentScrollOffset;
  double _scrollThreshold = 64;
  bool _loading = false;

  void _scrollListener() {
    _currentScrollOffset = _scrollController.offset;

    if (_scrollController.position.pixels + _scrollThreshold >=
        _scrollController.position.maxScrollExtent) {
      fetchMoreSongs();
    }
  }

  @override
  void initState() {
    super.initState();

    _songProvider = context.read<SongProvider>();
    _appState = context.read<AppStateProvider>();
    _paginationConfig =
        _appState.get('songs.paginationConfig') ?? SongPaginationConfig();

    _currentScrollOffset = _appState.get('songs.scrollOffSet') ?? 0.0;

    _scrollController = ScrollController(
      initialScrollOffset: _currentScrollOffset,
    );

    _scrollController.addListener(_scrollListener);

    fetchMoreSongs();
  }

  Future<void> fetchMoreSongs() async {
    if (_loading || _paginationConfig.page == null) return;

    setState(() => _loading = true);

    var result = await _songProvider.paginate(_paginationConfig);
    _paginationConfig.page = result.nextPage;

    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _loading = false;
    _appState.set('songs.scrollOffSet', _currentScrollOffset);
    _appState.set('songs.paginationConfig', _paginationConfig);
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SongProvider>(
        builder: (_, provider, __) {
          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              AppBar(
                headingText: 'All songs',
                actions: [
                  SortButton(
                    options: {
                      SortField.artist: 'Artist',
                      SortField.title: 'Song title',
                      SortField.recentlyAdded: 'Recently added',
                    },
                    currentSortField: _sortField,
                    onActionSheetActionPressed: (SortField order) {
                      setState(() => _sortField = order);

                      switch (order) {
                        case SortField.artist:
                          _paginationConfig.sortField = 'artist_name';
                          break;
                        case SortField.title:
                          _paginationConfig.sortField = 'title';
                          break;
                        case SortField.recentlyAdded:
                          _paginationConfig.sortField = 'created_at';
                          _paginationConfig.sortOrder = SortOrder.desc;
                          break;
                        default:
                          break;
                      }

                      _songProvider.songs.clear();

                      fetchMoreSongs();
                    },
                  ),
                ],
                coverImage: CoverImageStack(songs: provider.songs),
              ),
              SliverToBoxAdapter(child: SongListButtons(songs: provider.songs)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, int index) => SongRow(
                    song: provider.songs[index],
                    listContext: SongListContext.allSongs,
                  ),
                  childCount: provider.songs.length,
                ),
              ),
              _loading
                  ? SliverToBoxAdapter(
                      child: Container(
                        height: 72,
                        child: Center(child: const Spinner(size: 16)),
                      ),
                    )
                  : const SliverToBoxAdapter(),
              const BottomSpace(),
            ],
          );
        },
      ),
    );
  }
}

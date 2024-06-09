import 'package:app/app_state.dart';
import 'package:app/constants/constants.dart';
import 'package:app/enums.dart';
import 'package:app/extensions/extensions.dart';
import 'package:app/main.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/placeholders/placeholders.dart';
import 'package:app/ui/widgets/playable_list_header.dart' as BaseSongListHeader;
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/material.dart' hide AppBar;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

class SongsScreen extends StatefulWidget {
  static const routeName = '/songs';

  const SongsScreen({Key? key}) : super(key: key);

  @override
  _SongsScreenState createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  late final PlayableListScreenProvider _provider;

  final _paginationConfig =
      AppState.get('songs.paginationConfig', PlayablePaginationConfig())!;

  late final ScrollController _scrollController;
  var _currentScrollOffset = AppState.get('songs.scrollOffSet', 0.0)!;
  final _scrollThreshold = 64.0;
  var _searchQuery = '';
  var _cover = CoverImageStack(playables: []);
  var _loading = false;
  var _errored = false;
  var _inSearchMode = false;

  void _scrollListener() {
    _currentScrollOffset = _scrollController.offset;

    if (_inSearchMode) return;

    if (_scrollController.position.pixels + _scrollThreshold >=
        _scrollController.position.maxScrollExtent) {
      makeRequest();
    }
  }

  @override
  void initState() {
    super.initState();

    _provider = context.read();

    _scrollController = ScrollController(
      initialScrollOffset: _currentScrollOffset,
    );

    _scrollController.addListener(_scrollListener);

    makeRequest();
  }

  Future<void> makeRequest() async {
    if (_loading || (_paginationConfig.page == null && !_inSearchMode)) return;

    setState(() {
      _errored = false;
      _loading = true;
    });

    try {
      final result = await _provider.fetch(
        paginationConfig: _paginationConfig,
        searchQuery: _searchQuery,
      );

      if (result != null) {
        _paginationConfig.page = result.nextPage;
      }
    } catch (_) {
      setState(() => _errored = true);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _loading = false;
    AppState.set('songs.scrollOffSet', _currentScrollOffset);
    AppState.set('songs.paginationConfig', _paginationConfig);
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientDecoratedContainer(
        child: Consumer<PlayableListScreenProvider>(
          builder: (_, provider, __) {
            if (provider.playables.isEmpty) {
              if (_loading) return const PlayableListScreenPlaceholder();
              if (_errored) return OopsBox(onRetry: makeRequest);
            }

            if (_cover.isEmpty) {
              _cover = CoverImageStack(playables: provider.playables);
            }

            var displayedSongs = provider.playables;

            if (_inSearchMode) {
              // In search mode, sorting is done from the client side.
              displayedSongs =
                  displayedSongs.$sort(_paginationConfig.sortConfig);
            }

            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                AppBar(
                  headingText: 'All songs',
                  actions: [
                    SortButton(
                      fields: ['title', 'artist_name', 'created_at'],
                      currentField: _paginationConfig.sortField,
                      currentOrder: _paginationConfig.sortOrder,
                      onMenuItemSelected: (sortConfig) {
                        setState(() {
                          _paginationConfig.sortField = sortConfig.field;
                          _paginationConfig.sortOrder = sortConfig.order;
                        });

                        if (_inSearchMode) return;

                        // If we're not searching but displaying the full list,
                        // every time we sort, we fetch a new list of songs,
                        // since the sorting is done from the server.
                        provider.playables.clear();
                        makeRequest();
                      },
                    ),
                  ],
                  coverImage: _cover,
                ),
                SliverToBoxAdapter(
                  child: SongListHeader(
                    sortField: _paginationConfig.sortField,
                    sortOrder: _paginationConfig.sortOrder,
                    onSearchExpanded: () =>
                        setState(() => _inSearchMode = true),
                    onSearchCollapsed: () => setState(
                      () => _inSearchMode = false,
                    ),
                    onSearchQueryChanged: (query) {
                      setState(() => _searchQuery = query);
                      makeRequest();
                    },
                  ),
                ),
                SliverPlayableList(
                  playables: displayedSongs,
                  listContext: BaseSongListHeader.PlayableListContext.allSongs,
                ),
                _loading
                    ? SliverToBoxAdapter(
                        child: Container(
                          height: 72,
                          child: const Center(child: const Spinner(size: 16)),
                        ),
                      )
                    : const SliverToBoxAdapter(),
                const BottomSpace(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class SongListHeader extends StatefulWidget {
  final String sortField;
  final SortOrder sortOrder;
  final Function(String) onSearchQueryChanged;
  final Function() onSearchExpanded;
  final Function() onSearchCollapsed;

  const SongListHeader({
    Key? key,
    required this.sortField,
    required this.sortOrder,
    required this.onSearchQueryChanged,
    required this.onSearchExpanded,
    required this.onSearchCollapsed,
  }) : super(key: key);

  @override
  _SongListHeaderState createState() => _SongListHeaderState();
}

class _SongListHeaderState extends State<SongListHeader> {
  bool _fetchingSongsToPlayAll = false;
  bool _fetchingSongsToShuffle = false;

  late final PlayableProvider _playableProvider;

  @override
  initState() {
    super.initState();
    _playableProvider = context.read();
  }

  Future<void> fetchSongsToPlayAll() async {
    setState(() => _fetchingSongsToPlayAll = true);
    final songs = await _playableProvider.fetchInOrder(
      sortField: widget.sortField,
      order: widget.sortOrder,
    );
    setState(() => _fetchingSongsToPlayAll = false);
    audioHandler.replaceQueue(songs);
  }

  Future<void> fetchSongsToShuffleAll() async {
    setState(() => _fetchingSongsToShuffle = true);
    final songs = await _playableProvider.fetchRandom();
    setState(() => _fetchingSongsToShuffle = false);
    audioHandler.replaceQueue(songs, shuffle: true);
  }

  @override
  Widget build(BuildContext context) {
    return BaseSongListHeader.PlayableListHeader(
      playables: [],
      playIcon: _fetchingSongsToPlayAll
          ? SpinKitThreeBounce(color: AppColors.white.withOpacity(.5), size: 16)
          : null,
      shuffleIcon: _fetchingSongsToShuffle
          ? SpinKitThreeBounce(color: AppColors.white.withOpacity(.5), size: 16)
          : null,
      onSearchExpanded: widget.onSearchExpanded,
      onSearchCollapsed: widget.onSearchCollapsed,
      onSearchQueryChanged: widget.onSearchQueryChanged,
      onPlayPressed: () async {
        if (_fetchingSongsToPlayAll || _fetchingSongsToShuffle) return;
        await fetchSongsToPlayAll();
      },
      onShufflePressed: () async {
        if (_fetchingSongsToPlayAll || _fetchingSongsToShuffle) return;
        await fetchSongsToShuffleAll();
      },
    );
  }
}

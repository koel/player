import 'package:app/app_state.dart';
import 'package:app/enums.dart';
import 'package:app/extensions/extensions.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/placeholders/placeholders.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:app/values/values.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide AppBar;
import 'package:provider/provider.dart';

class GenreDetailsScreen extends StatefulWidget {
  static const routeName = '/genre';

  const GenreDetailsScreen({Key? key}) : super(key: key);

  @override
  _GenreDetailsScreenState createState() => _GenreDetailsScreenState();
}

class _GenreDetailsScreenState extends State<GenreDetailsScreen> {
  var _songs = <Playable>[];
  var _searchQuery = '';
  var _loading = false;
  var _initialLoading = true;
  var _errored = false;
  int? _nextPage = 1;
  final _scrollController = ScrollController();
  final _scrollThreshold = 64.0;

  Genre get _genre => ModalRoute.of(context)!.settings.arguments as Genre;

  late var _sortConfig = AppState.get(
    'genre.sort',
    PlayableSortConfig(field: 'title', order: SortOrder.asc),
  )!;

  void _scrollListener() {
    if (_scrollController.position.pixels + _scrollThreshold >=
        _scrollController.position.maxScrollExtent) {
      _fetchMore();
    }
  }

  Future<void> _fetchMore() async {
    if (_loading || _nextPage == null) return;

    setState(() => _loading = true);

    try {
      final result = await context.read<PlayableProvider>().paginateByGenre(
            _genre.id,
            page: _nextPage!,
            sort: _sortConfig.field,
            order: _sortConfig.order,
          );

      if (!mounted) return;

      setState(() {
        _songs = [..._songs, ...result.items].toSet().toList();
        _nextPage = result.nextPage;
        _initialLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _errored = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _errored = false;
    });

    try {
      final result = await context.read<PlayableProvider>().paginateByGenre(
            _genre.id,
            page: 1,
            sort: _sortConfig.field,
            order: _sortConfig.order,
          );

      if (!mounted) return;

      setState(() {
        _songs = result.items.toList();
        _nextPage = result.nextPage;
      });
    } catch (_) {
      if (mounted && _songs.isEmpty) {
        setState(() => _errored = true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialLoading) _fetchMore();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return Scaffold(
        body: GradientDecoratedContainer(
          child: _errored
              ? OopsBox(onRetry: _fetchMore)
              : const PlayableListScreenPlaceholder(),
        ),
      );
    }

    final displayedSongs = _songs.$sort(_sortConfig).$filter(_searchQuery);

    final showScrollbar = AlphabetScrollbar.shouldShow(
      itemCount: displayedSongs.length,
      sortField: _sortConfig.field,
      nameSortField: 'title',
    );

    return Scaffold(
      body: GradientDecoratedContainer(
        child: PullToRefresh(
          onRefresh: _refresh,
          child: PrimaryScrollController(
            controller: _scrollController,
            child: Stack(
              children: [
                CustomScrollView(
                  controller: _scrollController,
                  slivers: <Widget>[
                    AppBar(
                      headingText:
                          _genre.name.isEmpty ? 'Unknown Genre' : _genre.name,
                      backgroundImage: backgroundImageFromPlayables(_songs),
                      actions: [
                        SortButton(
                          fields: const [
                            'title',
                            'artist_name',
                            'album_name',
                          ],
                          currentField: _sortConfig.field,
                          currentOrder: _sortConfig.order,
                          onMenuItemSelected: (config) {
                            AppState.set('genre.sort', config);
                            setState(() {
                              _sortConfig = config;
                              _songs.clear();
                              _nextPage = 1;
                            });
                            _fetchMore();
                          },
                        ),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: _songs.isEmpty
                          ? const SizedBox.shrink()
                          : PlayableListHeader(
                              playables: displayedSongs,
                              scrollController: _scrollController,
                              rightPadding: showScrollbar ? alphabetScrollbarWidth / 2 : 0,
                              onSearchQueryChanged: (query) {
                                setState(() => _searchQuery = query);
                              },
                            ),
                    ),
                    SliverPlayableList(
                      playables: displayedSongs,
                      listContext: PlayableListContext.genre,
                      rightPadding: showScrollbar ? alphabetScrollbarWidth / 2 : 0,
                    ),
                    if (_loading)
                      SliverToBoxAdapter(
                        child: Container(
                          height: 72,
                          child: const Center(child: Spinner(size: 16)),
                        ),
                      ),
                    const BottomSpace(),
                  ],
                ),
                if (showScrollbar)
                  AlphabetScrollbar(
                    labels: displayedSongs.map((s) => s.title).toList(),
                    scrollController: _scrollController,
                    itemCount: displayedSongs.length,
                    scrollOffset: 100,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

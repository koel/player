import 'package:app/enums.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/widgets/app_bar.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/song_list_buttons.dart';
import 'package:app/ui/widgets/song_row.dart';
import 'package:app/ui/widgets/sortable_song_list.dart';
import 'package:app/ui/widgets/spinner.dart';
import 'package:flutter/cupertino.dart';
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
  late final SongProvider _songProvider;
  late final AppStateProvider _appState;
  late final SongPaginationConfig _paginationConfig;
  late final ScrollController _scrollController;
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
                    fields: ['title', 'artist_name', 'created_at'],
                    currentField: _paginationConfig.sortField,
                    currentOrder: _paginationConfig.sortOrder,
                    onActionSheetActionPressed: (sortConfig) {
                      _paginationConfig.sortField = sortConfig.field;
                      _paginationConfig.sortOrder = sortConfig.order;

                      _songProvider.songs.clear();
                      fetchMoreSongs();
                    },
                  ),
                ],
                coverImage: CoverImageStack(songs: provider.songs),
              ),
              SliverToBoxAdapter(
                child: SongListPrimaryButtons(
                    sortField: _paginationConfig.sortField,
                    sortOrder: _paginationConfig.sortOrder),
              ),
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

class SongListPrimaryButtons extends StatefulWidget {
  String sortField;
  SortOrder sortOrder;

  SongListPrimaryButtons({
    Key? key,
    required this.sortField,
    required this.sortOrder,
  }) : super(key: key);

  @override
  _SongListPrimaryButtonsState createState() => _SongListPrimaryButtonsState();
}

class _SongListPrimaryButtonsState extends State<SongListPrimaryButtons> {
  bool _fetchingSongsToPlayAll = false;
  bool _fetchingSongsToShuffle = false;

  @override
  Widget build(BuildContext context) {
    final SongProvider songProvider = context.read();
    final AudioProvider audio = context.read();

    return SongListButtons(
      songs: [],
      buttons: [
        ButtonConfig(
          label: 'Play All',
          icon: _fetchingSongsToPlayAll
              ? const SpinKitFadingCircle(color: Colors.white, size: 18)
              : const Icon(CupertinoIcons.play_fill),
          onPressed: () async {
            if (_fetchingSongsToPlayAll || _fetchingSongsToShuffle) return;

            setState(() => _fetchingSongsToPlayAll = true);
            final songs = await songProvider.fetchInOrder(
                sortField: widget.sortField, order: widget.sortOrder);
            setState(() => _fetchingSongsToPlayAll = false);
            await audio.replaceQueue(songs);
          },
        ),
        ButtonConfig(
          label: 'Shuffle All',
          icon: _fetchingSongsToShuffle
              ? const SpinKitFadingCircle(color: Colors.white, size: 18)
              : const Icon(CupertinoIcons.shuffle),
          onPressed: () async {
            if (_fetchingSongsToPlayAll || _fetchingSongsToShuffle) return;

            setState(() => _fetchingSongsToShuffle = true);
            final songs = await songProvider.fetchRandom();
            setState(() => _fetchingSongsToShuffle = false);
            await audio.replaceQueue(songs);
          },
        ),
      ],
    );
  }
}

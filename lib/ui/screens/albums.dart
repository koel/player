import 'package:app/app_state.dart';
import 'package:app/constants/constants.dart';
import 'package:app/enums.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/router.dart';
import 'package:app/ui/placeholders/placeholders.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:app/values/values.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AlbumsScreen extends StatefulWidget {
  static const routeName = '/albums';
  final AppRouter router;

  const AlbumsScreen({
    Key? key,
    this.router = const AppRouter(),
  }) : super(key: key);

  @override
  _AlbumsScreenState createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> {
  late final AlbumProvider _albumProvider;
  late final ScrollController _scrollController;
  var _currentScrollOffset = AppState.get('albums.scrollOffSet', 0.0)!;
  final _scrollThreshold = 64.0;
  var _errored = false;
  var _loading = false;

  void _scrollListener() {
    _currentScrollOffset = _scrollController.offset;

    if (_scrollController.position.pixels + _scrollThreshold >=
        _scrollController.position.maxScrollExtent) {
      fetchData();
    }
  }

  Future<void> fetchData() async {
    if (_loading) return;

    setState(() {
      _errored = false;
      _loading = true;
    });

    try {
      await _albumProvider.paginate();
    } catch (_) {
      setState(() => _errored = true);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();

    _albumProvider = context.read();

    _scrollController = ScrollController(
      initialScrollOffset: _currentScrollOffset,
    );

    _scrollController.addListener(_scrollListener);

    fetchData();
  }

  @override
  void dispose() {
    _loading = false;
    AppState.set('albums.scrollOffSet', _currentScrollOffset);
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientDecoratedContainer(
        child: Consumer<AlbumProvider>(
          builder: (_, provider, __) {
            if (provider.albums.isEmpty) {
              if (_loading) return const AlbumsScreenPlaceholder();
              if (_errored) return OopsBox(onRetry: fetchData);
            }

            final showScrollbar = AlphabetScrollbar.shouldShow(
              itemCount: provider.albums.length,
              sortField: _albumProvider.sortField,
              nameSortField: 'name',
            );

            return CupertinoTheme(
              data: const CupertinoThemeData(primaryColor: Colors.white),
              child: PullToRefresh(
                onRefresh: _albumProvider.refresh,
                child: ScrollsToTop(
                  scrollController: _scrollController,
                  child: Stack(
                    children: [
                    CustomScrollView(
                    controller: _scrollController,
                    slivers: <Widget>[
                      CupertinoSliverNavigationBar(
                        backgroundColor: AppColors.staticScreenHeaderBackground,
                        largeTitle: const LargeTitle(text: 'Albums'),
                        trailing: Transform.scale(
                          scale: 0.8,
                          alignment: Alignment.centerRight,
                          child: SortButton(
                          fields: const ['name', 'artist_name', 'year', 'created_at'],
                          currentField: _albumProvider.sortField,
                          currentOrder: _albumProvider.sortOrder,
                          onMenuItemSelected: (sortConfig) {
                            setState(() {
                              _albumProvider.sortField = sortConfig.field;
                              _albumProvider.sortOrder = sortConfig.order;
                            });

                            _albumProvider.albums.clear();
                            _albumProvider.refresh().then((_) {
                              if (_scrollController.hasClients) {
                                _scrollController.jumpTo(0);
                              }
                            });
                          },
                        ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.only(
                          right: showScrollbar ? alphabetScrollbarWidth : 0,
                        ),
                        sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (BuildContext context, int index) {
                            if (index >= provider.albums.length) return null;

                            return AlbumRow(
                              album: provider.albums[index],
                              router: widget.router,
                              sortField: _albumProvider.sortField,
                            );
                          },
                          childCount: provider.albums.length,
                        ),
                      )),
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
                  ),
                  if (showScrollbar)
                    AlphabetScrollbar(
                      labels: provider.albums.map((a) => a.name).toList(),
                      scrollController: _scrollController,
                      itemCount: provider.albums.length,
                      scrollOffset: 100,
                    ),
                  ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AlbumRow extends StatelessWidget {
  final Album album;
  final AppRouter router;
  final String sortField;

  const AlbumRow({
    Key? key,
    required this.album,
    required this.router,
    this.sortField = 'name',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => router.gotoAlbumDetailsScreen(
          context,
          albumId: album.id,
        ),
        child: ListTile(
          shape: Border(bottom: Divider.createBorderSide(context)),
          leading: AlbumArtistThumbnail.sm(entity: album, asHero: true),
          title: Text(album.name, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            album.artistName,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white60),
          ),
          trailing: sortField == 'year' && album.year != null
              ? Transform.translate(
                  offset: const Offset(8, -8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${album.year}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

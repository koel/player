import 'package:app/app_state.dart';
import 'package:app/constants/constants.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/router.dart';
import 'package:app/ui/placeholders/artists_screen_placeholder.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:app/values/values.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ArtistsScreen extends StatefulWidget {
  static const routeName = '/artists';
  final AppRouter router;

  const ArtistsScreen({
    Key? key,
    this.router = const AppRouter(),
  }) : super(key: key);

  @override
  _ArtistsScreenState createState() => _ArtistsScreenState();
}

class _ArtistsScreenState extends State<ArtistsScreen> {
  late final ArtistProvider _artistProvider;
  late final ScrollController _scrollController;
  var _currentScrollOffset = AppState.get('artists.scrollOffSet', 0.0)!;
  final _scrollThreshold = 64.0;
  var _loading = false;
  var _errored = false;

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
      await _artistProvider.paginate();
    } catch (_) {
      setState(() => _errored = true);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();

    _artistProvider = context.read();

    _scrollController = ScrollController(
      initialScrollOffset: _currentScrollOffset,
    );

    _scrollController.addListener(_scrollListener);

    fetchData();
  }

  @override
  void dispose() {
    _loading = false;
    AppState.set('artists.scrollOffSet', _currentScrollOffset);
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientDecoratedContainer(
        child: Consumer<ArtistProvider>(
          builder: (_, provider, __) {
            if (provider.artists.isEmpty) {
              if (_loading) return const ArtistsScreenPlaceholder();
              if (_errored) return OopsBox(onRetry: fetchData);
            }

            final showScrollbar = AlphabetScrollbar.shouldShow(
              itemCount: provider.artists.length,
              sortField: _artistProvider.sortField,
              nameSortField: 'name',
            );

            return CupertinoTheme(
              data: CupertinoThemeData(primaryColor: Colors.white),
              child: PullToRefresh(
                onRefresh: _artistProvider.refresh,
                child: PrimaryScrollController(
                  controller: _scrollController,
                  child: Stack(
                    children: [
                    CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      CupertinoSliverNavigationBar(enableBackgroundFilterBlur: false,
                        backgroundColor: highlightAccentColor,
                        largeTitle: const LargeTitle(text: 'Artists'),
                        trailing: Transform.scale(
                          scale: 0.8,
                          alignment: Alignment.centerRight,
                          child: SortButton(
                            fields: const ['name', 'created_at'],
                            currentField: _artistProvider.sortField,
                            currentOrder: _artistProvider.sortOrder,
                            onMenuItemSelected: (sortConfig) {
                              setState(() {
                                _artistProvider.sortField = sortConfig.field;
                                _artistProvider.sortOrder = sortConfig.order;
                              });

                              _artistProvider.artists.clear();
                              _artistProvider.refresh().then((_) {
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
                          delegate: SliverChildBuilderDelegate((
                            BuildContext context,
                            int index,
                          ) {
                            if (index >= provider.artists.length) return null;
                            final artist = provider.artists[index];
                            return SwipeToQueueDismissible(
                              dismissibleKey: ValueKey(artist.id),
                              fetchSongs: () => context
                                  .read<PlayableProvider>()
                                  .fetchForArtist(artist.id),
                              child: ArtistRow(
                                artist: artist,
                                router: widget.router,
                              ),
                            );
                          }, childCount: provider.artists.length),
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
                  ),
                  if (showScrollbar)
                    AlphabetScrollbar(
                      labels: provider.artists.map((a) => a.name).toList(),
                      scrollController: _scrollController,
                      itemCount: provider.artists.length,
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

class ArtistRow extends StatelessWidget {
  final Artist artist;
  final AppRouter router;

  const ArtistRow({Key? key, required this.artist, required this.router})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => router.gotoArtistDetailsScreen(
          context,
          artistId: artist.id,
        ),
        child: ListTile(
          shape: Border(bottom: Divider.createBorderSide(context)),
          leading: AlbumArtistThumbnail.sm(entity: artist, asHero: true),
          title: Text(artist.name, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}

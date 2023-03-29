import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/router.dart';
import 'package:app/ui/placeholders/placeholders.dart';
import 'package:app/ui/widgets/album_thumbnail.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/pull_to_refresh.dart';
import 'package:app/ui/widgets/spinner.dart';
import 'package:app/ui/widgets/typography.dart';
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
  late AlbumProvider _albumProvider;
  late AppStateProvider _appState;
  late ScrollController _scrollController;
  late double _currentScrollOffset;
  final _scrollThreshold = 64.0;
  var _loading = false;

  void _scrollListener() {
    _currentScrollOffset = _scrollController.offset;

    if (_scrollController.position.pixels + _scrollThreshold >=
        _scrollController.position.maxScrollExtent) {
      fetchMoreAlbums();
    }
  }

  @override
  void initState() {
    super.initState();

    _albumProvider = context.read();
    _appState = context.read();
    _currentScrollOffset = _appState.get('albums.scrollOffSet') ?? 0.0;

    _scrollController = ScrollController(
      initialScrollOffset: _currentScrollOffset,
    );

    _scrollController.addListener(_scrollListener);

    fetchMoreAlbums();
  }

  Future<void> fetchMoreAlbums() async {
    if (_loading) return;

    setState(() => _loading = true);
    await _albumProvider.paginate();
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _loading = false;
    _appState.set('albums.scrollOffSet', _currentScrollOffset);
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AlbumProvider>(
        builder: (_, provider, __) {
          if (provider.albums.isEmpty && _loading)
            return const AlbumScreenPlaceholder();

          return CupertinoTheme(
            data: const CupertinoThemeData(primaryColor: Colors.white),
            child: PullToRefresh(
              onRefresh: _albumProvider.refresh,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: <Widget>[
                  const CupertinoSliverNavigationBar(
                    backgroundColor: Colors.black54,
                    largeTitle: LargeTitle(text: 'Albums'),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        Album album = provider.albums[index];
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: Divider.createBorderSide(context),
                            ),
                          ),
                          child: InkWell(
                            onTap: () => widget.router.gotoAlbumDetailsScreen(
                              context,
                              albumId: album.id,
                            ),
                            child: ListTile(
                              leading: AlbumThumbnail(
                                albumId: album.id,
                                albumCoverUrl: album.cover,
                                asHero: true,
                              ),
                              title: Text(
                                album.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                album.artistName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: provider.albums.length,
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
            ),
          );
        },
      ),
    );
  }
}

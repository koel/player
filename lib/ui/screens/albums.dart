import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/router.dart';
import 'package:app/ui/widgets/album_thumbnail.dart';
import 'package:app/ui/widgets/bottom_space.dart';
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
  late AppStateProvider _appStateProvider;
  late ScrollController _scrollController;
  late double _currentScrollOffset;
  double _scrollThreshold = 64;
  bool _loading = false;

  void _scrollListener() {
    _currentScrollOffset = _scrollController.offset;

    if (_scrollController.position.pixels + _scrollThreshold >=
        _scrollController.position.maxScrollExtent) {
      fetchData();
    }
  }

  @override
  void initState() {
    super.initState();

    _albumProvider = context.read<AlbumProvider>();
    _appStateProvider = context.read<AppStateProvider>();
    _currentScrollOffset = _appStateProvider.get('albums.scrollOffSet') ?? 0.0;

    _scrollController = ScrollController(
      initialScrollOffset: _currentScrollOffset,
    );

    _scrollController.addListener(_scrollListener);

    fetchData();
  }

  Future<void> fetchData() async {
    if (_loading) return;

    setState(() => _loading = true);
    await _albumProvider.paginate();
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _loading = false;
    _appStateProvider.set('albums.scrollOffSet', _currentScrollOffset);
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AlbumProvider>(
        builder: (_, provider, __) {
          return CupertinoTheme(
            data: CupertinoThemeData(primaryColor: Colors.white),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: <Widget>[
                CupertinoSliverNavigationBar(
                  backgroundColor: Colors.black,
                  largeTitle: const LargeTitle(text: 'Albums'),
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
          );
        },
      ),
    );
  }
}

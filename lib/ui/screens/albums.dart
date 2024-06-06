import 'package:app/app_state.dart';
import 'package:app/constants/constants.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/router.dart';
import 'package:app/ui/placeholders/placeholders.dart';
import 'package:app/ui/widgets/widgets.dart';
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

            return CupertinoTheme(
              data: const CupertinoThemeData(primaryColor: Colors.white),
              child: PullToRefresh(
                onRefresh: _albumProvider.refresh,
                child: ScrollsToTop(
                  scrollController: _scrollController,
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: <Widget>[
                      const CupertinoSliverNavigationBar(
                        backgroundColor: AppColors.staticScreenHeaderBackground,
                        largeTitle: LargeTitle(text: 'Albums'),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (BuildContext context, int index) {
                            if (index >= provider.albums.length) return null;

                            return AlbumRow(
                              album: provider.albums[index],
                              router: widget.router,
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

  const AlbumRow({Key? key, required this.album, required this.router})
      : super(key: key);

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
        ),
      ),
    );
  }
}

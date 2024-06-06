import 'package:app/app_state.dart';
import 'package:app/constants/constants.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/router.dart';
import 'package:app/ui/placeholders/artists_screen_placeholder.dart';
import 'package:app/ui/widgets/widgets.dart';
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

            return CupertinoTheme(
              data: CupertinoThemeData(primaryColor: Colors.white),
              child: PullToRefresh(
                onRefresh: _artistProvider.refresh,
                child: ScrollsToTop(
                  scrollController: _scrollController,
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      const CupertinoSliverNavigationBar(
                        backgroundColor: AppColors.staticScreenHeaderBackground,
                        largeTitle: LargeTitle(text: 'Artists'),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate((
                          BuildContext context,
                          int index,
                        ) {
                          if (index >= provider.artists.length) return null;
                          return ArtistRow(
                            artist: provider.artists[index],
                            router: widget.router,
                          );
                        }, childCount: provider.artists.length),
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

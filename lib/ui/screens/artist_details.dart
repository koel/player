import 'package:app/app_state.dart';
import 'package:app/enums.dart';
import 'package:app/extensions/extensions.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/placeholders/placeholders.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:app/values/values.dart';
import 'package:flutter/material.dart' hide AppBar;
import 'package:provider/provider.dart';

class ArtistDetailsScreen extends StatefulWidget {
  static const routeName = '/artist';

  const ArtistDetailsScreen({Key? key}) : super(key: key);

  @override
  _ArtistDetailsScreenState createState() => _ArtistDetailsScreenState();
}

class _ArtistDetailsScreenState extends State<ArtistDetailsScreen> {
  var _searchQuery = '';
  final _scrollController = ScrollController();

  Future<List<Object>> buildRequest(dynamic artistId, {bool forceRefresh = false}) {
    return Future.wait([
      context
          .read<ArtistProvider>()
          .resolve(artistId, forceRefresh: forceRefresh),
      context
          .read<PlayableProvider>()
          .fetchForArtist(artistId, forceRefresh: forceRefresh),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final artistId = ModalRoute.of(context)!.settings.arguments;
    var sortConfig = AppState.get(
      'artist.sort',
      PlayableSortConfig(field: 'title', order: SortOrder.asc),
    )!;

    return Scaffold(
      body: GradientDecoratedContainer(
        child: FutureBuilder(
          future: buildRequest(artistId),
          builder: (_, AsyncSnapshot<List<dynamic>> snapshot) {
            if (!snapshot.hasData ||
                snapshot.connectionState == ConnectionState.active)
              return const PlayableListScreenPlaceholder();

            if (snapshot.hasError)
              return OopsBox(onRetry: () => setState(() {}));

            final songs = snapshot.requireData[1] as List<Playable>;

            final artist = snapshot.requireData[0] as Artist;
            final displayedSongs =
                songs.$sort(sortConfig).$filter(_searchQuery);

            return PullToRefresh(
              onRefresh: () async {
                await buildRequest(artistId, forceRefresh: true);
                if (mounted) setState(() {});
              },
              child: PrimaryScrollController(
                controller: _scrollController,
                child: Stack(
                  children: [
                  CustomScrollView(
                  controller: _scrollController,
                  slivers: <Widget>[
                    AppBar(
                      headingText: artist.name,
                      actions: [
                        SortButton(
                          fields: ['title', 'album_name', 'created_at'],
                          currentField: sortConfig.field,
                          currentOrder: sortConfig.order,
                          onMenuItemSelected: (_sortConfig) {
                            setState(() => sortConfig = _sortConfig);
                            AppState.set('artist.sort', sortConfig);
                          },
                        ),
                      ],
                      backgroundImage: Hero(
                        tag: 'artist-hero-${artist.id}',
                        child: SizedBox.expand(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: artist.image,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (songs.isNotEmpty)
                      SliverToBoxAdapter(
                        child: PlayableListHeader(
                          playables: displayedSongs,
                          scrollController: _scrollController,
                          onSearchQueryChanged: (String query) {
                            setState(() => _searchQuery = query);
                          },
                        ),
                      ),
                    SliverPlayableList(
                      playables: displayedSongs,
                      listContext: PlayableListContext.artist,
                    ),
                    const BottomSpace(),
                  ],
                ),
                if (AlphabetScrollbar.shouldShow(itemCount: displayedSongs.length, sortField: sortConfig.field, nameSortField: 'title'))
                  AlphabetScrollbar(
                    labels: displayedSongs.map((s) => s.title).toList(),
                    scrollController: _scrollController,
                    itemCount: displayedSongs.length,
                    scrollOffset: 250,
                  ),
                ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

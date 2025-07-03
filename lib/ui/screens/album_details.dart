import 'dart:ui';

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

class AlbumDetailsScreen extends StatefulWidget {
  static const routeName = '/album';

  const AlbumDetailsScreen({Key? key}) : super(key: key);

  _AlbumDetailsScreenState createState() => _AlbumDetailsScreenState();
}

class _AlbumDetailsScreenState extends State<AlbumDetailsScreen> {
  var _searchQuery = '';

  Future<List<Object>> buildRequest(dynamic albumId, {bool forceRefresh = false}) {
    return Future.wait([
      context
          .read<AlbumProvider>()
          .resolve(albumId, forceRefresh: forceRefresh),
      context
          .read<PlayableProvider>()
          .fetchForAlbum(albumId, forceRefresh: forceRefresh),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final albumId = ModalRoute.of(context)!.settings.arguments;

    var sortConfig = AppState.get(
      'album.sort',
      PlayableSortConfig(field: 'track', order: SortOrder.asc),
    )!;

    return Scaffold(
      body: GradientDecoratedContainer(
        child: FutureBuilder(
          future: buildRequest(albumId),
          builder: (_, AsyncSnapshot<List<Object>> snapshot) {
            if (!snapshot.hasData ||
                snapshot.connectionState == ConnectionState.active)
              return const PlayableListScreenPlaceholder();

            if (snapshot.hasError)
              return OopsBox(onRetry: () => setState(() {}));

            final songs = snapshot.data == null
                ? <Song>[]
                : snapshot.requireData[1] as List<Playable>;

            final album = snapshot.requireData[0] as Album;
            final displayedPlayables =
                songs.$sort(sortConfig).$filter(_searchQuery);

            return PullToRefresh(
              onRefresh: () => buildRequest(albumId, forceRefresh: true),
              child: ScrollsToTop(
                child: CustomScrollView(
                  slivers: <Widget>[
                    AppBar(
                      headingText: album.name,
                      actions: [
                        SortButton(
                          fields: ['track', 'title', 'created_at'],
                          currentField: sortConfig.field,
                          currentOrder: sortConfig.order,
                          onMenuItemSelected: (_sortConfig) {
                            setState(() => sortConfig = _sortConfig);
                            AppState.set('album.sort', sortConfig);
                          },
                        ),
                      ],
                      backgroundImage: SizedBox.square(
                        dimension: double.infinity,
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(
                            sigmaX: 20.0,
                            sigmaY: 20.0,
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: album.image,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                              ),
                            ),
                          ),
                        ),
                      ),
                      coverImage: Hero(
                        tag: "album-hero-${album.id}",
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: album.image,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            ),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(16),
                            ),
                            boxShadow: const <BoxShadow>[
                              const BoxShadow(
                                color: Colors.black38,
                                blurRadius: 10.0,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (songs.isNotEmpty)
                      SliverToBoxAdapter(
                        child: PlayableListHeader(
                          playables: displayedPlayables,
                          onSearchQueryChanged: (String query) {
                            setState(() => _searchQuery = query);
                          },
                        ),
                      ),
                    SliverPlayableList(
                      playables: displayedPlayables,
                      listContext: PlayableListContext.album,
                    ),
                    const BottomSpace(),
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

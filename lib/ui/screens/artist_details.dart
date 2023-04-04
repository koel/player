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

class ArtistDetailsScreen extends StatefulWidget {
  static const routeName = '/artist';

  const ArtistDetailsScreen({Key? key}) : super(key: key);

  @override
  _ArtistDetailsScreenState createState() => _ArtistDetailsScreenState();
}

class _ArtistDetailsScreenState extends State<ArtistDetailsScreen> {
  var _searchQuery = '';
  var cover = CoverImageStack(songs: []);

  Future<List<Object>> buildRequest(int artistId, {bool forceRefresh = false}) {
    return Future.wait([
      context
          .read<ArtistProvider>()
          .resolve(artistId, forceRefresh: forceRefresh),
      context
          .read<SongProvider>()
          .fetchForArtist(artistId, forceRefresh: forceRefresh),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final artistId = ModalRoute.of(context)!.settings.arguments as int;
    var sortConfig = AppState.get(
      'artist.sort',
      SongSortConfig(field: 'title', order: SortOrder.asc),
    )!;

    return Scaffold(
      body: GradientDecoratedContainer(
        child: FutureBuilder(
          future: buildRequest(artistId),
          builder: (_, AsyncSnapshot<List<dynamic>> snapshot) {
            if (!snapshot.hasData ||
                snapshot.connectionState == ConnectionState.active)
              return const SongListScreenPlaceholder();

            if (snapshot.hasError)
              return OopsBox(onRetry: () => setState(() {}));

            final songs = snapshot.requireData[1] as List<Song>;

            if (cover.isEmpty) {
              cover = CoverImageStack(songs: songs);
            }

            final artist = snapshot.requireData[0] as Artist;
            final displayedSongs =
                songs.$sort(sortConfig).$filter(_searchQuery);

            return PullToRefresh(
              onRefresh: () => buildRequest(artistId, forceRefresh: true),
              child: CustomScrollView(
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
                    backgroundImage: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(
                          sigmaX: 20.0,
                          sigmaY: 20.0,
                        ),
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
                    coverImage: Hero(
                      tag: "artist-hero-${artist.id}",
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: artist.image,
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
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (songs.isNotEmpty)
                    SliverToBoxAdapter(
                      child: SongListHeader(
                        songs: displayedSongs,
                        onSearchQueryChanged: (String query) {
                          setState(() => _searchQuery = query);
                        },
                      ),
                    ),
                  SliverSongList(
                    songs: displayedSongs,
                    listContext: SongListContext.artist,
                  ),
                  const BottomSpace(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

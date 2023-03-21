import 'dart:ui';

import 'package:app/enums.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/widgets/app_bar.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/pull_to_refresh.dart';
import 'package:app/ui/widgets/song_list_buttons.dart';
import 'package:app/ui/widgets/song_row.dart';
import 'package:app/ui/widgets/sortable_song_list.dart';
import 'package:app/ui/widgets/spinner.dart';
import 'package:flutter/material.dart' hide AppBar;
import 'package:provider/provider.dart';

class AlbumDetailsScreen extends StatefulWidget {
  static const routeName = '/album';

  const AlbumDetailsScreen({Key? key}) : super(key: key);

  _AlbumDetailsScreenState createState() => _AlbumDetailsScreenState();
}

class _AlbumDetailsScreenState extends State<AlbumDetailsScreen> {
  Future<List<Object>> buildRequest(int albumId, {bool forceRefresh = false}) {
    return Future.wait([
      context
          .read<AlbumProvider>()
          .resolve(albumId, forceRefresh: forceRefresh),
      context
          .read<SongProvider>()
          .fetchForAlbum(albumId, forceRefresh: forceRefresh),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    int albumId = ModalRoute.of(context)!.settings.arguments as int;
    AppStateProvider appState = context.read();
    SongSortConfig sortConfig = appState.get('album.sort') ??
        SongSortConfig(field: 'track', order: SortOrder.asc);

    return Scaffold(
      body: FutureBuilder(
        future: buildRequest(albumId),
        builder: (_, AsyncSnapshot<List<Object>> snapshot) {
          if (!snapshot.hasData || snapshot.hasError) {
            return const Center(child: const Spinner());
          }

          var album = snapshot.data![0] as Album;
          var songs = sortSongs(
            snapshot.data![1] as List<Song>,
            field: sortConfig.field,
            order: sortConfig.order,
          );

          return PullToRefresh(
            onRefresh: () => buildRequest(albumId, forceRefresh: true),
            child: CustomScrollView(
              slivers: <Widget>[
                AppBar(
                  headingText: album.name,
                  actions: [
                    SortButton(
                      fields: ['track', 'title', 'created_at'],
                      currentField: sortConfig.field,
                      currentOrder: sortConfig.order,
                      onActionSheetActionPressed: (_sortConfig) {
                        setState(() => sortConfig = _sortConfig);
                        appState.set('album.sort', sortConfig);
                      },
                    ),
                  ],
                  backgroundImage: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
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
                  SliverToBoxAdapter(child: SongListButtons(songs: songs)),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, int index) => SongRow(
                      song: songs[index],
                      listContext: SongListContext.album,
                    ),
                    childCount: songs.length,
                  ),
                ),
                const BottomSpace(),
              ],
            ),
          );
        },
      ),
    );
  }
}

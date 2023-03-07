import 'dart:ui';

import 'package:app/models/album.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/album_provider.dart';
import 'package:app/providers/song_provider.dart';
import 'package:app/ui/widgets/app_bar.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/song_list_buttons.dart';
import 'package:app/ui/widgets/song_row.dart';
import 'package:app/ui/widgets/sortable_song_list.dart';
import 'package:flutter/material.dart' hide AppBar;
import 'package:provider/provider.dart';

OrderBy _currentSortOrder = OrderBy.trackNumber;

class AlbumDetailsScreen extends StatefulWidget {
  static const routeName = '/album';

  const AlbumDetailsScreen({Key? key}) : super(key: key);

  _AlbumDetailsScreenState createState() => _AlbumDetailsScreenState();
}

class _AlbumDetailsScreenState extends State<AlbumDetailsScreen> {
  OrderBy _sortOrder = _currentSortOrder;
  late AlbumProvider albumProvider;
  late SongProvider songProvider;
  late Album album;
  late List<Song> songs;

  @override
  void initState() {
    super.initState();

    albumProvider = context.read();
    songProvider = context.read();
  }

  @override
  Widget build(BuildContext context) {
    int albumId = ModalRoute.of(context)!.settings.arguments as int;
    Future<Album> futureAlbum = albumProvider.resolve(albumId);
    Future<List<Song>> futureSongs = songProvider.fetchForAlbum(albumId);

    return Scaffold(
      body: FutureBuilder(
        future: Future.wait([futureAlbum, futureSongs]),
        builder: (_, AsyncSnapshot<List<dynamic>> snapshot) {
          if (!snapshot.hasData || snapshot.hasError) {
            return const Center(child: const CircularProgressIndicator());
          }

          album = snapshot.data![0] as Album;
          songs = snapshot.data![1] as List<Song>;

          songs = sortSongs(songs, orderBy: _sortOrder);

          return CustomScrollView(
            slivers: <Widget>[
              AppBar(
                headingText: album.name,
                actions: [
                  SortButton(
                    options: {
                      OrderBy.trackNumber: 'Track number',
                      OrderBy.title: 'Song title',
                      OrderBy.recentlyAdded: 'Recently added',
                    },
                    currentOrder: _sortOrder,
                    onActionSheetActionPressed: (OrderBy order) {
                      _currentSortOrder = order;
                      setState(() => _sortOrder = order);
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
          );
        },
      ),
    );
  }
}

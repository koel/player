import 'dart:ui';

import 'package:app/models/artist.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/song_provider.dart';
import 'package:app/ui/widgets/app_bar.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/song_list_buttons.dart';
import 'package:app/ui/widgets/song_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide AppBar;
import 'package:provider/provider.dart';

enum OrderBy {
  album,
  title,
  recentlyAdded,
}

Map<OrderBy, String> _sortOptions = {
  OrderBy.title: 'Song title',
  OrderBy.album: 'Album',
  OrderBy.recentlyAdded: 'Recently added',
};

OrderBy _currentSortOrder = OrderBy.title;

class ArtistDetailsScreen extends StatefulWidget {
  static const routeName = '/artist';

  const ArtistDetailsScreen({Key? key}) : super(key: key);

  @override
  _ArtistDetailsScreenState createState() => _ArtistDetailsScreenState();
}

class _ArtistDetailsScreenState extends State<ArtistDetailsScreen> {
  late Artist artist;
  late List<Song> songs;
  late SongProvider songProvider;
  late OrderBy _sortOrder;

  @override
  void initState() {
    super.initState();
    songProvider = context.read();
    setState(() => _sortOrder = _currentSortOrder);
  }

  List<Song> sortSongs({required OrderBy orderBy}) {
    switch (orderBy) {
      case OrderBy.title:
        return songs..sort((a, b) => a.title.compareTo(b.title));
      case OrderBy.album:
        return songs
          ..sort((a, b) => '${a.album.name}${a.albumId}${a.track}'
              .compareTo('${b.album.name}${b.albumId}${b.track}'));
      case OrderBy.recentlyAdded:
        return songs..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      default:
        throw Exception('Invalid order.');
    }
  }

  @override
  Widget build(BuildContext context) {
    artist = ModalRoute.of(context)!.settings.arguments as Artist;
    songs = songProvider.byArtist(artist);
    List<Song> sortedSongs = sortSongs(orderBy: _sortOrder);

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          AppBar(
            headingText: artist.name,
            actions: [
              IconButton(
                  onPressed: () {
                    showCupertinoModalPopup(
                      context: context,
                      builder: (BuildContext context) => CupertinoActionSheet(
                        title: const Text('Sort by'),
                        actions: _sortOptions.entries
                            .map(
                              (entry) => CupertinoActionSheetAction(
                                onPressed: () {
                                  _currentSortOrder = entry.key;
                                  setState(() => _sortOrder = entry.key);
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  (entry.key == _currentSortOrder
                                          ? '✓ '
                                          : ' ') +
                                      entry.value,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    );
                  },
                  icon: Icon(CupertinoIcons.sort_down)),
            ],
            backgroundImage: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
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
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: SongListButtons(songs: sortedSongs)),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, int index) => SongRow(
                song: sortedSongs[index],
                listContext: SongListContext.artist,
              ),
              childCount: sortedSongs.length,
            ),
          ),
          const SliverToBoxAdapter(child: const BottomSpace()),
        ],
      ),
    );
  }
}

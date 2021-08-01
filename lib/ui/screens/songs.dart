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
  artist,
  title,
  recentlyAdded,
}

Map<OrderBy, String> sortOptions = {
  OrderBy.artist: 'Artist',
  OrderBy.title: 'Song title',
  OrderBy.recentlyAdded: 'Recently added',
};

OrderBy _currentSortOrder = OrderBy.recentlyAdded;

class SongsScreen extends StatefulWidget {
  static const routeName = '/songs';

  const SongsScreen({Key? key}) : super(key: key);

  @override
  _SongsScreenState createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  late SongProvider songProvider;
  late List<Song> songs;
  late OrderBy _sortOrder = _currentSortOrder;

  @override
  void initState() {
    super.initState();
    songProvider = context.read();
    songs = songProvider.songs;
  }

  List<Song> sortSongs({required OrderBy orderBy}) {
    switch (orderBy) {
      case OrderBy.title:
        return songs..sort((a, b) => a.title.compareTo(b.title));
      case OrderBy.artist:
        return songs..sort((a, b) => a.artist.name.compareTo(b.artist.name));
      case OrderBy.recentlyAdded:
        return songs..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      default:
        throw Exception('Invalid order.');
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Song> sortedSongs = sortSongs(orderBy: _sortOrder);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppBar(
            headingText: 'All songs',
            actions: [
              IconButton(
                onPressed: () {
                  showCupertinoModalPopup(
                    context: context,
                    builder: (BuildContext context) => CupertinoActionSheet(
                      title: const Text('Sort by'),
                      actions: sortOptions.entries
                          .map(
                            (entry) => CupertinoActionSheetAction(
                              onPressed: () {
                                _currentSortOrder = entry.key;
                                setState(() => _sortOrder = entry.key);
                                Navigator.pop(context);
                              },
                              child: Text(
                                (entry.key == _currentSortOrder ? '✓ ' : ' ') +
                                    entry.value,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  );
                },
                icon: Icon(CupertinoIcons.sort_down),
              )
            ],
            coverImage: songProvider.coverImageStack,
          ),
          SliverToBoxAdapter(child: SongListButtons(songs: sortedSongs)),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, int index) => SongRow(
                song: sortedSongs[index],
                listContext: SongListContext.allSongs,
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

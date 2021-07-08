import 'package:app/models/song.dart';
import 'package:app/providers/song_provider.dart';
import 'package:app/ui/widgets/app_bar.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/song_list.dart';
import 'package:app/ui/widgets/song_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide AppBar;
import 'package:provider/provider.dart';

enum OrderBy {
  Artist,
  Title,
  RecentlyAdded,
}

Map<OrderBy, String> sortOptions = {
  OrderBy.Artist: 'Artist',
  OrderBy.Title: 'Song title',
  OrderBy.RecentlyAdded: 'Recently added',
};

OrderBy _currentSortOrder = OrderBy.RecentlyAdded;

class SongsScreen extends StatefulWidget {
  final String? previousPageTitle;

  const SongsScreen({Key? key, this.previousPageTitle}) : super(key: key);

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
      case OrderBy.Title:
        return songs..sort((a, b) => a.title.compareTo(b.title));
      case OrderBy.Artist:
        return songs..sort((a, b) => a.artist.name.compareTo(b.artist.name));
      case OrderBy.RecentlyAdded:
        return songs..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      default:
        throw Exception('Invalid order.');
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Song> sortedSongs = sortSongs(orderBy: _sortOrder);

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          AppBar(
            headingText: 'All songs',
            actions: [
              IconButton(
                onPressed: () {
                  showCupertinoModalPopup(
                    context: context,
                    builder: (BuildContext context) => CupertinoActionSheet(
                      title: Text('Sort by'),
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
            coverImage: CoverImageStack(songs: sortedSongs),
          ),
          SliverToBoxAdapter(child: SongListButtons(songs: sortedSongs)),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, int index) => SongRow(song: sortedSongs[index]),
              childCount: sortedSongs.length,
            ),
          ),
          SliverToBoxAdapter(child: bottomSpace()),
        ],
      ),
    );
  }
}

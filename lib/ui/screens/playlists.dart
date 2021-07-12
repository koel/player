import 'package:app/models/playlist.dart';
import 'package:app/providers/playlist_provider.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/playlist_row.dart';
import 'package:app/ui/widgets/typography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlaylistsScreen extends StatefulWidget {
  final String? previousPageTitle;

  const PlaylistsScreen({Key? key, this.previousPageTitle}) : super(key: key);

  @override
  _PlaylistsScreenState createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  late PlaylistProvider playlistProvider;
  late List<Playlist> _playlists = [];

  @override
  void initState() {
    super.initState();
    playlistProvider = context.read();
    setState(() => _playlists = playlistProvider.playlists);

    // Try to populate all playlists even before user interactions to update
    // the playlist's thumbnail and song count.
    playlistProvider.populateAllPlaylists();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: <Widget>[
          CupertinoSliverNavigationBar(
            backgroundColor: Colors.black,
            previousPageTitle: widget.previousPageTitle,
            largeTitle: const LargeTitle(text: 'Playlists'),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) =>
                  PlaylistRow(playlist: _playlists[index]),
              childCount: _playlists.length,
            ),
          ),
          const SliverToBoxAdapter(child: const BottomSpace()),
        ],
      ),
    );
  }
}

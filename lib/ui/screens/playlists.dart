import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/playlist.dart';
import 'package:app/providers/playlist_provider.dart';
import 'package:app/router.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/playlist_row.dart';
import 'package:app/ui/widgets/typography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlaylistsScreen extends StatefulWidget {
  static const routeName = '/playlists';
  final AppRouter router;

  const PlaylistsScreen({
    Key? key,
    this.router = const AppRouter(),
  }) : super(key: key);

  @override
  _PlaylistsScreenState createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen>
    with StreamSubscriber {
  late PlaylistProvider playlistProvider;
  late List<Playlist> _playlists = [];

  @override
  void initState() {
    super.initState();

    playlistProvider = context.read();

    subscribe(playlistProvider.playlistCreatedStream.listen((playlist) {
      setState(() => _playlists = playlistProvider.playlists);
    }));

    setState(() => _playlists = playlistProvider.playlists);

    // Try to populate all playlists even before user interactions to update
    // the playlist's thumbnail and song count.
    playlistProvider.populateAllPlaylists();
  }

  @override
  void dispose() {
    unsubscribeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CupertinoTheme(
        data: CupertinoThemeData(primaryColor: Colors.white),
        child: CustomScrollView(
          slivers: <Widget>[
            CupertinoSliverNavigationBar(
              backgroundColor: Colors.black,
              largeTitle: const LargeTitle(text: 'Playlists'),
              trailing: IconButton(
                onPressed: () => widget.router.showCreatePlaylistSheet(context),
                icon: Icon(CupertinoIcons.add_circled),
              ),
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
      ),
    );
  }
}

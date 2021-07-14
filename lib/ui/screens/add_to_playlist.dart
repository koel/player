import 'package:app/models/playlist.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/playlist_provider.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/playlist_row.dart';
import 'package:app/ui/widgets/typography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddToPlaylistScreen extends StatefulWidget {
  static const routeName = '/add-to-playlist';

  const AddToPlaylistScreen({Key? key}) : super(key: key);

  @override
  _AddToPlaylistScreenState createState() => _AddToPlaylistScreenState();
}

class _AddToPlaylistScreenState extends State<AddToPlaylistScreen> {
  late Song song;
  late PlaylistProvider playlistProvider;
  late List<Playlist> _playlists = [];

  @override
  void initState() {
    super.initState();
    playlistProvider = context.read();
    setState(() => _playlists = playlistProvider.standardPlaylist);
  }

  @override
  Widget build(BuildContext context) {
    song = ModalRoute.of(context)!.settings.arguments as Song;

    return Scaffold(
      body: CupertinoTheme(
        data: CupertinoThemeData(
          primaryColor: Colors.white,
        ),
        child: CustomScrollView(
          slivers: <Widget>[
            CupertinoSliverNavigationBar(
              backgroundColor: Colors.black,
              largeTitle: const LargeTitle(text: 'Add to a Playlist'),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) => PlaylistRow(
                  playlist: _playlists[index],
                  onTap: () async {
                    playlistProvider.addSongToPlaylist(
                      song: song,
                      playlist: _playlists[index],
                    );
                    Navigator.pop(context);
                  },
                ),
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

void gotoAddToPlaylistScreen(BuildContext context, {required Song song}) {
  Navigator.of(context, rootNavigator: true).pushNamed(
    AddToPlaylistScreen.routeName,
    arguments: song,
  );
}

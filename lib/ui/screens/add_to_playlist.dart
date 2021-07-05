import 'package:app/models/playlist.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/playlist_provider.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/playlist_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddToPlaylistScreen extends StatefulWidget {
  final Song song;

  AddToPlaylistScreen({Key? key, required this.song}) : super(key: key);

  @override
  _AddToPlaylistScreenState createState() => _AddToPlaylistScreenState();
}

class _AddToPlaylistScreenState extends State<AddToPlaylistScreen> {
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
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          CupertinoSliverNavigationBar(
            backgroundColor: Colors.black,
            largeTitle: const Text(
              'Add to a Playlist',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) => PlaylistRow(
                playlist: _playlists[index],
                onTap: () async {
                  playlistProvider.addSongToPlaylist(
                    song: widget.song,
                    playlist: _playlists[index],
                  );
                  Navigator.of(context).pop();
                },
              ),
              childCount: _playlists.length,
            ),
          ),
          SliverToBoxAdapter(child: bottomSpace()),
        ],
      ),
    );
  }
}

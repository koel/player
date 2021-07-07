import 'package:app/models/playlist.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/playlist_provider.dart';
import 'package:app/ui/widgets/app_bar.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/song_list.dart';
import 'package:app/ui/widgets/song_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide AppBar;
import 'package:provider/provider.dart';

class PlaylistDetailsScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailsScreen({Key? key, required this.playlist})
      : super(key: key);

  @override
  _PlaylistDetailsScreen createState() => _PlaylistDetailsScreen();
}

class _PlaylistDetailsScreen extends State<PlaylistDetailsScreen> {
  late PlaylistProvider playlistProvider;
  late Future<Playlist> futurePlaylist;

  @override
  void initState() {
    super.initState();
    playlistProvider = context.read();
    futurePlaylist = playlistProvider.populatePlaylist(
      playlist: widget.playlist,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: futurePlaylist,
        builder: (BuildContext context, AsyncSnapshot<Playlist> snapshot) {
          if (!snapshot.hasData || snapshot.hasError) {
            return CustomScrollView(
              slivers: <Widget>[
                AppBar(
                  headingText: widget.playlist.name,
                  coverImage: CoverImageStack(
                    songs: widget.playlist.songs,
                  ),
                ),
              ],
            );
          }

          Playlist playlist = snapshot.data!;

          return CustomScrollView(
            slivers: <Widget>[
              AppBar(
                headingText: widget.playlist.name,
                coverImage: CoverImageStack(
                  songs: widget.playlist.songs,
                ),
              ),
              SliverToBoxAdapter(
                child: playlist.isEmpty
                    ? const SizedBox.shrink()
                    : SongListButtons(songs: playlist.songs),
              ),
              if (playlist.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Center(
                      child: Text(
                        'The playlist is empty.',
                        style: TextStyle(
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, int index) {
                      final bool dismissible = widget.playlist.isStandard;
                      final Song song = widget.playlist.songs[index];
                      return Dismissible(
                        direction: dismissible
                            ? DismissDirection.endToStart
                            : DismissDirection.none,
                        onDismissed: dismissible
                            ? (DismissDirection direction) =>
                                playlistProvider.removeSongFromPlaylist(
                                  song: song,
                                  playlist: widget.playlist,
                                )
                            : null,
                        background: Container(
                          alignment: AlignmentDirectional.centerEnd,
                          color: Colors.red,
                          child: const Padding(
                            padding: EdgeInsets.only(right: 28),
                            child: Icon(CupertinoIcons.delete_simple),
                          ),
                        ),
                        key: ValueKey(song),
                        child: SongRow(
                          key: ValueKey(song),
                          song: song,
                        ),
                      );
                    },
                    childCount: playlist.songs.length,
                  ),
                ),
              SliverToBoxAdapter(child: bottomSpace()),
            ],
          );
        },
      ),
    );
  }
}

void gotoDetailsScreen(BuildContext context, {required Playlist playlist}) {
  Navigator.of(context).push(CupertinoPageRoute<void>(
    builder: (_) => PlaylistDetailsScreen(playlist: playlist),
    title: playlist.name,
  ));
}

import 'package:app/models/playlist.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/playlist_provider.dart';
import 'package:app/ui/widgets/app_bar.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/song_list_buttons.dart';
import 'package:app/ui/widgets/song_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide AppBar;
import 'package:provider/provider.dart';

class PlaylistDetailsScreen extends StatefulWidget {
  static const routeName = '/playlist';

  const PlaylistDetailsScreen({Key? key}) : super(key: key);

  @override
  _PlaylistDetailsScreen createState() => _PlaylistDetailsScreen();
}

class _PlaylistDetailsScreen extends State<PlaylistDetailsScreen> {
  late Playlist playlist;
  late PlaylistProvider playlistProvider;
  late Future<Playlist> futurePlaylist;

  @override
  void initState() {
    super.initState();
    playlistProvider = context.read();
  }

  @override
  Widget build(BuildContext context) {
    playlist = ModalRoute.of(context)!.settings.arguments as Playlist;
    futurePlaylist = playlistProvider.populatePlaylist(
      playlist: playlist,
    );

    return Scaffold(
      body: FutureBuilder(
        future: futurePlaylist,
        builder: (BuildContext context, AsyncSnapshot<Playlist> snapshot) {
          if (!snapshot.hasData || snapshot.hasError) {
            return CustomScrollView(
              slivers: <Widget>[
                AppBar(
                  headingText: playlist.name,
                  coverImage: CoverImageStack(
                    songs: playlist.songs,
                  ),
                ),
              ],
            );
          }

          Playlist populatedPlaylist = snapshot.data!;

          return CustomScrollView(
            slivers: <Widget>[
              AppBar(
                headingText: populatedPlaylist.name,
                coverImage: CoverImageStack(songs: populatedPlaylist.songs),
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
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, int index) {
                      final bool dismissible = populatedPlaylist.isStandard;
                      final Song song = populatedPlaylist.songs[index];
                      return dismissible
                          ? Dismissible(
                              direction: DismissDirection.endToStart,
                              onDismissed: (DismissDirection direction) {
                                playlistProvider.removeSongFromPlaylist(
                                  song: song,
                                  playlist: populatedPlaylist,
                                );
                              },
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
                            )
                          : SongRow(song: song);
                    },
                    childCount: playlist.songs.length,
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

void gotoDetailsScreen(BuildContext context, {required Playlist playlist}) {
  Navigator.of(context, rootNavigator: true).pushNamed(
    PlaylistDetailsScreen.routeName,
    arguments: playlist,
  );
}

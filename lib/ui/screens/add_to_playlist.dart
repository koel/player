import 'package:app/models/playlist.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/playlist_provider.dart';
import 'package:app/router.dart';
import 'package:app/ui/screens/playlists.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/message_overlay.dart';
import 'package:app/ui/widgets/playlist_row.dart';
import 'package:app/ui/widgets/typography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AddToPlaylistScreen extends StatelessWidget {
  static const routeName = '/add-to-playlist';

  final AppRouter router;

  const AddToPlaylistScreen({
    Key? key,
    this.router = const AppRouter(),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Song song = ModalRoute.of(context)!.settings.arguments as Song;

    return Scaffold(
      body: CupertinoTheme(
        data: CupertinoThemeData(primaryColor: Colors.white),
        child: Consumer<PlaylistProvider>(
          builder: (context, provider, navigationBar) {
            if (provider.standardPlaylists.isEmpty) {
              return NoPlaylistsScreen(
                onTap: () => router.showCreatePlaylistSheet(context),
              );
            }

            return CustomScrollView(
              slivers: <Widget>[
                navigationBar!,
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      Playlist playlist = provider.standardPlaylists[index];

                      return PlaylistRow(
                        playlist: playlist,
                        onTap: () {
                          provider.addSongToPlaylist(
                            song: song,
                            playlist: playlist,
                          );
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                          showOverlay(
                            context,
                            icon: CupertinoIcons.text_badge_plus,
                            caption: 'Added',
                            message: 'Song added to playlist.',
                          );
                        },
                      );
                    },
                    childCount: provider.standardPlaylists.length,
                  ),
                ),
                const BottomSpace(),
              ],
            );
          },
          child: CupertinoSliverNavigationBar(
            backgroundColor: Colors.black,
            largeTitle: const LargeTitle(text: 'Add to a Playlist'),
            trailing: IconButton(
              onPressed: () => router.showCreatePlaylistSheet(context),
              icon: const Icon(CupertinoIcons.add_circled),
            ),
          ),
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

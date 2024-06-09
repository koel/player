import 'package:app/constants/constants.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/router.dart';
import 'package:app/ui/screens/screens.dart';
import 'package:app/ui/widgets/widgets.dart';
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
    final playable = ModalRoute.of(context)!.settings.arguments as Playable;

    return Scaffold(
      body: CupertinoTheme(
        data: const CupertinoThemeData(primaryColor: Colors.white),
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
                          provider.addToPlaylist(playable, playlist: playlist);
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                          showOverlay(
                            context,
                            icon: CupertinoIcons.text_badge_plus,
                            caption: 'Added',
                            message: 'Item added to playlist.',
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
            backgroundColor: AppColors.staticScreenHeaderBackground,
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

void gotoAddToPlaylistScreen(
  BuildContext context, {
  required Playable playable,
}) {
  Navigator.of(context, rootNavigator: true).pushNamed(
    AddToPlaylistScreen.routeName,
    arguments: playable,
  );
}

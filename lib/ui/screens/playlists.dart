import 'package:app/constants/colors.dart';
import 'package:app/constants/dimensions.dart';
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

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  @override
  void initState() {
    super.initState();

    // Try to populate all playlists even before user interactions to update
    // the playlist's thumbnail and song count.
    context.read<PlaylistProvider>().populateAllPlaylists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CupertinoTheme(
        data: CupertinoThemeData(primaryColor: Colors.white),
        child: Consumer<PlaylistProvider>(
          builder: (context, provider, navigationBar) {
            if (provider.playlists.isEmpty) {
              return NoPlaylistsScreen(
                onTap: () => widget.router.showCreatePlaylistSheet(context),
              );
            }

            return CustomScrollView(
              slivers: <Widget>[
                navigationBar!,
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      Playlist playlist = provider.playlists[index];

                      return Dismissible(
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) async => await confirmDelete(
                          context,
                          playlist: playlist,
                        ),
                        onDismissed: (_) => provider.remove(
                          playlist: playlist,
                        ),
                        background: Container(
                          alignment: AlignmentDirectional.centerEnd,
                          color: Colors.red,
                          child: const Padding(
                            padding: EdgeInsets.only(right: 28),
                            child: Icon(CupertinoIcons.delete),
                          ),
                        ),
                        key: ValueKey(playlist),
                        child: PlaylistRow(playlist: playlist),
                      );
                    },
                    childCount: provider.playlists.length,
                  ),
                ),
                const BottomSpace(),
              ],
            );
          },
          child: CupertinoSliverNavigationBar(
            backgroundColor: Colors.black,
            largeTitle: const LargeTitle(text: 'Playlists'),
            trailing: IconButton(
              onPressed: () => widget.router.showCreatePlaylistSheet(context),
              icon: const Icon(CupertinoIcons.add_circled),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> confirmDelete(
    BuildContext context, {
    required Playlist playlist,
  }) async {
    return await showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: <InlineSpan>[
                const TextSpan(text: 'Delete the playlist '),
                TextSpan(
                  text: playlist.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: '?'),
              ],
            ),
          ),
          content: const Text('You cannot undo this action.'),
          actions: <Widget>[
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context, false),
            ),
            CupertinoDialogAction(
              child: const Text('Confirm'),
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );
  }
}

class NoPlaylistsScreen extends StatelessWidget {
  final void Function() onTap;

  const NoPlaylistsScreen({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.horizontalPadding,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                CupertinoIcons.exclamationmark_square,
                size: 56.0,
                color: AppColors.red,
              ),
              const SizedBox(height: 16.0),
              Text(
                'No playlists',
                style: Theme.of(context).textTheme.headline5,
              ),
              const SizedBox(height: 16.0),
              const Text('Tap to create a playlist.'),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:app/constants/constants.dart';
import 'package:app/main.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/router.dart';
import 'package:app/ui/widgets/widgets.dart';
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
  var _loading = false;
  final _expandedFolders = <String>{};

  @override
  void initState() {
    super.initState();
    makeRequest();
  }

  Future<void> makeRequest() async {
    if (_loading) return;

    setState(() => _loading = true);

    try {
      await Future.wait([
        context.read<PlaylistProvider>().fetchAll(),
        context.read<PlaylistFolderProvider>().fetchAll(),
      ]);
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  void _toggleFolder(String folderId) {
    setState(() {
      if (_expandedFolders.contains(folderId)) {
        _expandedFolders.remove(folderId);
      } else {
        _expandedFolders.add(folderId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CupertinoTheme(
        data: const CupertinoThemeData(primaryColor: Colors.white),
        child: GradientDecoratedContainer(
          child: Consumer2<PlaylistProvider, PlaylistFolderProvider>(
            builder: (context, playlistProvider, folderProvider, navigationBar) {
              final allPlaylists = playlistProvider.playlists;
              final folders = folderProvider.folders
                ..sort((a, b) => a.name.compareTo(b.name));

              late var widgets = <Widget>[];

              if (allPlaylists.isEmpty) {
                widgets = [
                  SliverToBoxAdapter(
                    child: NoPlaylistsScreen(
                      onTap: () {
                        widget.router.showCreatePlaylistSheet(context);
                      },
                    ),
                  )
                ];
              } else {
                final rootPlaylists = allPlaylists
                    .where((p) => p.folderId == null)
                    .toList()
                  ..sort((a, b) => a.name.compareTo(b.name));

                final sliverItems = <Widget>[];

                // Folders
                for (final folder in folders) {
                  final folderPlaylists = allPlaylists
                      .where((p) => p.folderId == folder.id)
                      .toList()
                    ..sort((a, b) => a.name.compareTo(b.name));

                  final isExpanded = _expandedFolders.contains(folder.id);

                  sliverItems.add(
                    Card(
                      child: Dismissible(
                        direction: DismissDirection.startToEnd,
                        confirmDismiss: (_) async {
                          final playableProvider = context.read<PlayableProvider>();
                          final results = await Future.wait(
                            folderPlaylists.map((p) => playableProvider
                                .fetchForPlaylist(p.id)
                                .catchError((_) => <Playable>[])),
                          );
                          final songs = results.expand((s) => s).toList();
                          if (songs.isNotEmpty) {
                            for (final song in songs) {
                              await audioHandler.queueToBottom(song);
                            }
                            showOverlay(context, caption: 'Queued');
                          } else {
                            showOverlay(context, caption: 'No songs found.', icon: CupertinoIcons.nosign);
                          }
                          return false;
                        },
                        background: Container(
                          alignment: AlignmentDirectional.centerStart,
                          color: Colors.green,
                          child: const Padding(
                            padding: EdgeInsets.only(left: 28),
                            child: Icon(CupertinoIcons.text_badge_plus),
                          ),
                        ),
                        key: ValueKey(folder.id),
                        child: _FolderRow(
                          folder: folder,
                          playlistCount: folderPlaylists.length,
                          isExpanded: isExpanded,
                          onTap: () => _toggleFolder(folder.id),
                        ),
                      ),
                    ),
                  );

                  if (isExpanded) {
                    for (final playlist in folderPlaylists) {
                      sliverItems.add(
                        _buildPlaylistRow(
                          playlist,
                          indented: true,
                        ),
                      );
                    }
                  }
                }

                // Root-level playlists
                for (final playlist in rootPlaylists) {
                  sliverItems.add(
                    _buildPlaylistRow(playlist),
                  );
                }

                widgets = [
                  navigationBar!,
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        if (index >= sliverItems.length) return null;
                        return sliverItems[index];
                      },
                      childCount: sliverItems.length,
                    ),
                  ),
                  const BottomSpace(),
                ];
              }

              return PullToRefresh(
                onRefresh: () => _loading ? Future(() => null) : makeRequest(),
                child: CustomScrollView(slivers: widgets),
              );
            },
            child: CupertinoSliverNavigationBar(
              backgroundColor: AppColors.staticScreenHeaderBackground,
              largeTitle: const LargeTitle(text: 'Playlists'),
              trailing: PopupMenuButton<String>(
                icon: const Icon(CupertinoIcons.add_circled),
                offset: const Offset(-12, 48),
                onSelected: (value) {
                  if (value == 'playlist') {
                    widget.router.showCreatePlaylistSheet(context);
                  } else if (value == 'folder') {
                    widget.router.showCreatePlaylistFolderSheet(context);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'playlist',
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.music_note_list, size: 18),
                        SizedBox(width: 12),
                        Text('New Playlist'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'folder',
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.folder, size: 18),
                        SizedBox(width: 12),
                        Text('New Folder'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistRow(
    Playlist playlist, {
    bool indented = false,
  }) {
    return Card(
      child: Dismissible(
        direction: DismissDirection.startToEnd,
        confirmDismiss: (_) async {
          final playableProvider = context.read<PlayableProvider>();
          final songs = await playableProvider.fetchForPlaylist(playlist.id);
          if (songs.isNotEmpty) {
            for (final song in songs) {
              await audioHandler.queueToBottom(song);
            }
            showOverlay(context, caption: 'Queued');
          } else {
            showOverlay(context, caption: 'No songs found.', icon: CupertinoIcons.nosign);
          }
          return false;
        },
        background: Container(
          alignment: AlignmentDirectional.centerStart,
          color: Colors.green,
          child: const Padding(
            padding: EdgeInsets.only(left: 28),
            child: Icon(CupertinoIcons.text_badge_plus),
          ),
        ),
        key: ValueKey(playlist.id),
        child: Padding(
          padding: EdgeInsets.only(left: indented ? 24 : 0),
          child: PlaylistRow(playlist: playlist),
        ),
      ),
    );
  }

}

class _FolderRow extends StatelessWidget {
  final PlaylistFolder folder;
  final int playlistCount;
  final bool isExpanded;
  final VoidCallback onTap;

  const _FolderRow({
    Key? key,
    required this.folder,
    required this.playlistCount,
    required this.isExpanded,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ListTile(
        shape: Border(bottom: Divider.createBorderSide(context)),
        leading: Icon(
          isExpanded ? CupertinoIcons.folder_open : CupertinoIcons.folder,
          color: Colors.white54,
        ),
        title: Text(folder.name, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '$playlistCount playlist${playlistCount == 1 ? '' : 's'}',
          style: const TextStyle(color: Colors.white54),
        ),
        trailing: Icon(
          isExpanded
              ? CupertinoIcons.chevron_down
              : CupertinoIcons.chevron_forward,
          size: 16,
          color: Colors.white54,
        ),
      ),
    );
  }
}

class NoPlaylistsScreen extends StatelessWidget {
  final void Function() onTap;

  const NoPlaylistsScreen({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      alignment: Alignment.center,
      child: Wrap(
        spacing: 16.0,
        direction: Axis.vertical,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          const Icon(
            CupertinoIcons.exclamationmark_square,
            size: 56.0,
          ),
          const Text('You have no playlists in your library.'),
          ElevatedButton(onPressed: onTap, child: Text('Create Playlist')),
        ],
      ),
    );
  }
}

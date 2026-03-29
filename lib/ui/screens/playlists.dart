import 'package:app/constants/constants.dart';
import 'package:app/main.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/router.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                        direction: DismissDirection.horizontal,
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            final playableProvider = context.read<PlayableProvider>();
                            final songs = <Playable>[];
                            for (final p in folderPlaylists) {
                              songs.addAll(await playableProvider.fetchForPlaylist(p.id));
                            }
                            if (songs.isNotEmpty) {
                              for (final song in songs) {
                                await audioHandler.queueToBottom(song);
                              }
                              showOverlay(context, caption: 'Queued');
                            } else {
                              showOverlay(context, caption: 'No songs found.', icon: CupertinoIcons.nosign);
                            }
                            return false;
                          }
                          final confirmed = await _confirmDeleteFolder(
                            context,
                            folder: folder,
                          );
                          if (confirmed) {
                            for (final p in folderPlaylists) {
                              p.folderId = null;
                            }
                            folderProvider.remove(folder);
                            _expandedFolders.remove(folder.id);
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
                        secondaryBackground: Container(
                          alignment: AlignmentDirectional.centerEnd,
                          color: AppColors.red,
                          child: const Padding(
                            padding: EdgeInsets.only(right: 28),
                            child: Icon(CupertinoIcons.delete),
                          ),
                        ),
                        key: ValueKey(folder.id),
                        child: _FolderRow(
                          folder: folder,
                          playlistCount: folderPlaylists.length,
                          isExpanded: isExpanded,
                          onTap: () => _toggleFolder(folder.id),
                          onLongPress: () => _showFolderActions(
                            context,
                            folder: folder,
                            playlists: folderPlaylists,
                            folderProvider: folderProvider,
                          ),
                        ),
                      ),
                    ),
                  );

                  if (isExpanded) {
                    for (final playlist in folderPlaylists) {
                      sliverItems.add(
                        _buildDismissiblePlaylist(
                          playlist,
                          playlistProvider,
                          indented: true,
                        ),
                      );
                    }
                  }
                }

                // Root-level playlists
                for (final playlist in rootPlaylists) {
                  sliverItems.add(
                    _buildDismissiblePlaylist(playlist, playlistProvider),
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
            child: CupertinoSliverNavigationBar(enableBackgroundFilterBlur: false,
              backgroundColor: Colors.transparent,
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

  Future<void> _showFolderActions(
    BuildContext context, {
    required PlaylistFolder folder,
    required List<Playlist> playlists,
    required PlaylistFolderProvider folderProvider,
  }) async {
    HapticFeedback.mediumImpact();
    final playableProvider = context.read<PlayableProvider>();

    await showCupertinoModalPopup(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: Text(folder.name),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(sheetContext);
              final songs = <Playable>[];
              for (final p in playlists) {
                songs.addAll(await playableProvider.fetchForPlaylist(p.id));
              }
              if (songs.isNotEmpty) {
                audioHandler.replaceQueue(songs);
              } else {
                showOverlay(context, caption: 'No songs found.', icon: CupertinoIcons.nosign);
              }
            },
            child: const Text('Play All'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(sheetContext);
              final songs = <Playable>[];
              for (final p in playlists) {
                songs.addAll(await playableProvider.fetchForPlaylist(p.id));
              }
              if (songs.isNotEmpty) {
                audioHandler.replaceQueue(songs, shuffle: true);
              } else {
                showOverlay(context, caption: 'No songs found.', icon: CupertinoIcons.nosign);
              }
            },
            child: const Text('Shuffle All'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(sheetContext);
              _showRenameFolder(context, folder: folder, provider: folderProvider);
            },
            child: const Text('Rename'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(sheetContext);
              final confirmed = await _confirmDeleteFolder(context, folder: folder);
              if (confirmed) {
                for (final p in playlists) {
                  p.folderId = null;
                }
                folderProvider.remove(folder);
                _expandedFolders.remove(folder.id);
              }
            },
            child: const Text('Delete'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheetContext),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _showRenameFolder(
    BuildContext context, {
    required PlaylistFolder folder,
    required PlaylistFolderProvider provider,
  }) async {
    final controller = TextEditingController(text: folder.name);

    await showFormSheet(
      context,
      title: 'Rename Folder',
      submitLabel: 'Save',
      canSubmit: () => controller.text.trim().isNotEmpty,
      onSubmit: () async {
        final name = controller.text.trim();
        if (name.isEmpty) return;
        try {
          await provider.rename(folder, name: name);
          Navigator.pop(context);
        } catch (_) {
          showOverlay(context,
            caption: 'Error',
            message: 'Could not rename folder.',
            icon: Icons.error_outline,
          );
        }
      },
      builder: (context, setState) {
        return FormTextField(
          controller: controller,
          autofocus: true,
          onChanged: (_) => setState(() {}),
        );
      },
    );
  }

  Future<bool> _confirmDeleteFolder(
    BuildContext context, {
    required PlaylistFolder folder,
  }) async {
    return await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Delete "${folder.name}"?'),
        content: const Text(
          'Playlists in this folder will not be deleted.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _buildDismissiblePlaylist(
    Playlist playlist,
    PlaylistProvider provider, {
    bool indented = false,
  }) {
    return Card(
      child: Dismissible(
        direction: DismissDirection.horizontal,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
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
          }
          final confirmed = await confirmDelete(context, playlist: playlist);
          if (confirmed) provider.remove(playlist);
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
        secondaryBackground: Container(
          alignment: AlignmentDirectional.centerEnd,
          color: AppColors.red,
          child: const Padding(
            padding: EdgeInsets.only(right: 28),
            child: Icon(CupertinoIcons.delete),
          ),
        ),
        key: ValueKey(playlist),
        child: GestureDetector(
          onLongPress: () => _showPlaylistActions(
            context,
            playlist: playlist,
            provider: provider,
          ),
          child: Padding(
            padding: EdgeInsets.only(left: indented ? 24 : 0),
            child: PlaylistRow(playlist: playlist),
          ),
        ),
      ),
    );
  }

  Future<void> _showPlaylistActions(
    BuildContext context, {
    required Playlist playlist,
    required PlaylistProvider provider,
  }) async {
    HapticFeedback.mediumImpact();
    final playableProvider = context.read<PlayableProvider>();
    final folderProvider = context.read<PlaylistFolderProvider>();

    await showCupertinoModalPopup(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: Text(playlist.name),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(sheetContext);
              final songs = await playableProvider.fetchForPlaylist(playlist.id);
              if (songs.isNotEmpty) {
                audioHandler.replaceQueue(songs);
              } else {
                showOverlay(context, caption: 'No songs found.', icon: CupertinoIcons.nosign);
              }
            },
            child: const Text('Play'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(sheetContext);
              final songs = await playableProvider.fetchForPlaylist(playlist.id);
              if (songs.isNotEmpty) {
                audioHandler.replaceQueue(songs, shuffle: true);
              } else {
                showOverlay(context, caption: 'No songs found.', icon: CupertinoIcons.nosign);
              }
            },
            child: const Text('Shuffle'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(sheetContext);
              final songs = await playableProvider.fetchForPlaylist(playlist.id);
              if (songs.isNotEmpty) {
                for (final song in songs) {
                  await audioHandler.queueToBottom(song);
                }
                showOverlay(context, caption: 'Queued');
              } else {
                showOverlay(context, caption: 'No songs found.', icon: CupertinoIcons.nosign);
              }
            },
            child: const Text('Queue'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(sheetContext);
              _showEditPlaylist(
                context,
                playlist: playlist,
                provider: provider,
                folderProvider: folderProvider,
              );
            },
            child: const Text('Edit'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(sheetContext);
              final confirmed = await confirmDelete(context, playlist: playlist);
              if (confirmed) provider.remove(playlist);
            },
            child: const Text('Delete'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheetContext),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _showEditPlaylist(
    BuildContext context, {
    required Playlist playlist,
    required PlaylistProvider provider,
    required PlaylistFolderProvider folderProvider,
  }) async {
    final nameController = TextEditingController(text: playlist.name);
    final descController =
        TextEditingController(text: playlist.description ?? '');
    final folders = folderProvider.folders;
    String? selectedFolderId = playlist.folderId;

    await showFormSheet(
      context,
      title: 'Edit Playlist',
      submitLabel: 'Save',
      canSubmit: () => nameController.text.trim().isNotEmpty,
      onSubmit: () async {
        final name = nameController.text.trim();
        if (name.isEmpty) return;

        try {
          await provider.update(
            playlist,
            name: name,
            description: descController.text.trim(),
            folderId: selectedFolderId,
          );
          Navigator.pop(context);
          showOverlay(context, caption: 'Playlist updated');
        } catch (_) {
          showOverlay(context,
            caption: 'Error',
            message: 'Could not update playlist.',
            icon: Icons.error_outline,
          );
        }
      },
      builder: (context, setState) {
        return Column(
          children: [
            FormTextField(
              controller: nameController,
              placeholder: 'Playlist Name',
              autofocus: true,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            FormTextField(
              controller: descController,
              placeholder: 'Description (optional)',
              maxLines: 2,
            ),
            if (folders.isNotEmpty) ...[
              const SizedBox(height: 8),
              FormDropdown<String?>(
                value: selectedFolderId,
                items: [null, ...folders.map((f) => f.id)],
                labelBuilder: (id) {
                  if (id == null) return 'No folder';
                  final folder = folders.cast<dynamic>().firstWhere(
                    (f) => f.id == id, orElse: () => null);
                  return folder?.name ?? 'No folder';
                },
                placeholder: 'No folder',
                onChanged: (id) => setState(() => selectedFolderId = id),
              ),
            ],
          ],
        );
      },
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

class _FolderRow extends StatelessWidget {
  final PlaylistFolder folder;
  final int playlistCount;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _FolderRow({
    Key? key,
    required this.folder,
    required this.playlistCount,
    required this.isExpanded,
    required this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
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

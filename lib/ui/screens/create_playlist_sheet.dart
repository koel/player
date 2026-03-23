import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> showCreatePlaylistDialog(BuildContext context) async {
  final nameController = TextEditingController();
  final descController = TextEditingController();
  final playlistProvider = context.read<PlaylistProvider>();
  final folderProvider = context.read<PlaylistFolderProvider>();
  final folders = folderProvider.folders;
  String? selectedFolderId;

  await showCupertinoDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final selectedFolder = selectedFolderId == null
              ? null
              : folders.firstWhere((f) => f.id == selectedFolderId);

          return CupertinoAlertDialog(
            title: const Text('New Playlist'),
            content: Column(
              children: [
                const SizedBox(height: 12),
                CupertinoTextField(
                  controller: nameController,
                  placeholder: 'Playlist Name',
                  autofocus: true,
                  decoration: BoxDecoration(
                    color: CupertinoColors.tertiarySystemFill,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: descController,
                  placeholder: 'Description (optional)',
                  maxLines: 2,
                  decoration: BoxDecoration(
                    color: CupertinoColors.tertiarySystemFill,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                if (folders.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      showCupertinoModalPopup(
                        context: context,
                        builder: (_) => CupertinoActionSheet(
                          title: const Text('Select Folder'),
                          actions: [
                            CupertinoActionSheetAction(
                              onPressed: () {
                                setState(() => selectedFolderId = null);
                                Navigator.pop(context);
                              },
                              child: Text(
                                'No folder',
                                style: TextStyle(
                                  color: selectedFolderId == null
                                      ? CupertinoColors.activeBlue
                                      : CupertinoColors.white,
                                ),
                              ),
                            ),
                            ...folders.map(
                              (f) => CupertinoActionSheetAction(
                                onPressed: () {
                                  setState(() => selectedFolderId = f.id);
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  f.name,
                                  style: TextStyle(
                                    color: selectedFolderId == f.id
                                        ? CupertinoColors.activeBlue
                                        : CupertinoColors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          cancelButton: CupertinoActionSheetAction(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.tertiarySystemFill,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.folder,
                            size: 16,
                            color: CupertinoColors.systemGrey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedFolder?.name ?? 'No folder',
                              style: TextStyle(
                                fontSize: 14,
                                color: selectedFolder != null
                                    ? CupertinoColors.white
                                    : CupertinoColors.placeholderText,
                              ),
                            ),
                          ),
                          const Icon(
                            CupertinoIcons.chevron_down,
                            size: 12,
                            color: CupertinoColors.systemGrey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('Create'),
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;

                  try {
                    await playlistProvider.create(
                      name: name,
                      description: descController.text.trim(),
                      folderId: selectedFolderId,
                    );
                    Navigator.pop(context);
                    showOverlay(context, caption: 'Playlist added');
                  } catch (_) {
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}

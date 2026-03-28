import 'package:app/providers/providers.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> showCreatePlaylistDialog(BuildContext context) async {
  final nameController = TextEditingController();
  final descController = TextEditingController();
  final playlistProvider = context.read<PlaylistProvider>();
  final folderProvider = context.read<PlaylistFolderProvider>();
  final folders = folderProvider.folders;
  String? selectedFolderId;

  await showFormSheet(
    context,
    title: 'New Playlist',
    submitLabel: 'Create',
    canSubmit: () => nameController.text.trim().isNotEmpty,
    onSubmit: () async {
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
        showOverlay(context,
          caption: 'Error',
          message: 'Could not create playlist.',
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

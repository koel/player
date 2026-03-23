import 'package:app/providers/providers.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> showCreatePlaylistFolderDialog(BuildContext context) async {
  final controller = TextEditingController();
  final folderProvider = context.read<PlaylistFolderProvider>();

  await showCupertinoDialog(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        title: const Text('New Folder'),
        content: Column(
          children: [
            const SizedBox(height: 4),
            const Text('Enter a name for this folder.'),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: controller,
              placeholder: 'Folder Name',
              autofocus: true,
              decoration: BoxDecoration(
                color: CupertinoColors.tertiarySystemFill,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
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
              final name = controller.text.trim();
              if (name.isEmpty) return;

              try {
                await folderProvider.create(name: name);
                Navigator.pop(context);
                showOverlay(context, caption: 'Folder created');
              } catch (_) {
                Navigator.pop(context);
              }
            },
          ),
        ],
      );
    },
  );
}

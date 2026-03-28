import 'package:app/providers/providers.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> showCreatePlaylistFolderDialog(BuildContext context) async {
  final controller = TextEditingController();
  final folderProvider = context.read<PlaylistFolderProvider>();

  await showFormSheet(
    context,
    title: 'New Folder',
    submitLabel: 'Create',
    canSubmit: () => controller.text.trim().isNotEmpty,
    onSubmit: () async {
      final name = controller.text.trim();
      if (name.isEmpty) return;

      try {
        await folderProvider.create(name: name);
        Navigator.pop(context);
        showOverlay(context, caption: 'Folder created');
      } catch (_) {
        showOverlay(context,
          caption: 'Error',
          message: 'Could not create folder.',
          icon: Icons.error_outline,
        );
      }
    },
    builder: (context, setState) {
      return FormTextField(
        controller: controller,
        placeholder: 'Folder Name',
        autofocus: true,
        onChanged: (_) => setState(() {}),
      );
    },
  );
}

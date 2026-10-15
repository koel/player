import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> showEditArtistDialog(
  BuildContext context, {
  required Artist artist,
}) async {
  final nameController = TextEditingController(text: artist.name);
  final artistProvider = context.read<ArtistProvider>();

  await showFormSheet(
    context,
    title: 'Edit Artist',
    submitLabel: 'Save',
    canSubmit: () => nameController.text.trim().isNotEmpty,
    onSubmit: (sheetContext) async {
      final name = nameController.text.trim();
      if (name.isEmpty) return;

      try {
        await artistProvider.update(artist, name: name);
        if (!sheetContext.mounted) return;
        Navigator.pop(sheetContext);
        showOverlay(sheetContext, caption: 'Artist updated');
      } catch (_) {
        if (!sheetContext.mounted) return;
        showOverlay(
          sheetContext,
          caption: 'Error',
          message: 'Could not update artist.',
          icon: Icons.error_outline,
        );
      }
    },
    builder: (context, setState) {
      return Column(
        children: [
          FormTextField(
            controller: nameController,
            placeholder: 'Artist Name',
            autofocus: true,
            onChanged: (_) => setState(() {}),
          ),
        ],
      );
    },
  );
}

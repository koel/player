import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

Future<void> showEditAlbumDialog(
  BuildContext context, {
  required Album album,
}) async {
  final nameController = TextEditingController(text: album.name);
  final yearController =
      TextEditingController(text: album.year?.toString() ?? '');
  final albumProvider = context.read<AlbumProvider>();

  await showFormSheet(
    context,
    title: 'Edit Album',
    submitLabel: 'Save',
    canSubmit: () => nameController.text.trim().isNotEmpty,
    onSubmit: () async {
      final name = nameController.text.trim();
      if (name.isEmpty) return;

      final yearText = yearController.text.trim();
      final year = yearText.isEmpty ? null : int.tryParse(yearText);

      try {
        await albumProvider.update(album, name: name, year: year);
        Navigator.pop(context);
        showOverlay(context, caption: 'Album updated');
      } catch (_) {
        showOverlay(
          context,
          caption: 'Error',
          message: 'Could not update album.',
          icon: Icons.error_outline,
        );
      }
    },
    builder: (context, setState) {
      return Column(
        children: [
          FormTextField(
            controller: nameController,
            placeholder: 'Album Name',
            autofocus: true,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          FormTextField(
            controller: yearController,
            placeholder: 'Year (optional)',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
          ),
        ],
      );
    },
  );
}

import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> showEditRadioStationDialog(
  BuildContext context, {
  required RadioStation station,
}) async {
  final nameController = TextEditingController(text: station.name);
  final urlController = TextEditingController(text: station.url);
  final descController =
      TextEditingController(text: station.description ?? '');
  final stationProvider = context.read<RadioStationProvider>();

  await showFormSheet(
    context,
    title: 'Edit Station',
    submitLabel: 'Save',
    canSubmit: () =>
        nameController.text.trim().isNotEmpty &&
        urlController.text.trim().isNotEmpty,
    onSubmit: () async {
      final name = nameController.text.trim();
      final url = urlController.text.trim();
      if (name.isEmpty || url.isEmpty) return;

      try {
        await stationProvider.update(
          station,
          name: name,
          url: url,
          description: descController.text.trim(),
          // Preserve the existing public/private flag — toggling it is
          // out of scope for this form.
          isPublic: station.isPublic,
        );
        Navigator.pop(context);
        showOverlay(context, caption: 'Station updated');
      } catch (_) {
        showOverlay(
          context,
          caption: 'Error',
          message: 'Could not update station.',
          icon: Icons.error_outline,
        );
      }
    },
    builder: (context, setState) {
      return Column(
        children: [
          FormTextField(
            controller: nameController,
            placeholder: 'Station Name',
            autofocus: true,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          FormTextField(
            controller: urlController,
            placeholder: 'Stream URL',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          FormTextField(
            controller: descController,
            placeholder: 'Description (optional)',
            maxLines: 2,
          ),
        ],
      );
    },
  );
}

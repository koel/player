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
  var isPublic = station.isPublic;
  final stationProvider = context.read<RadioStationProvider>();
  final radioPlayer = context.read<RadioPlayerProvider>();

  await showFormSheet(
    context,
    title: 'Edit Station',
    submitLabel: 'Save',
    canSubmit: () =>
        nameController.text.trim().isNotEmpty &&
        urlController.text.trim().isNotEmpty,
    onSubmit: (sheetContext) async {
      final name = nameController.text.trim();
      final url = urlController.text.trim();
      if (name.isEmpty || url.isEmpty) return;

      // Capture before mutation so we can detect what actually changed
      // and bring the live player into sync.
      final oldUrl = station.url;
      final oldName = station.name;

      try {
        await stationProvider.update(
          station,
          name: name,
          url: url,
          description: descController.text.trim(),
          isPublic: isPublic,
        );

        if (radioPlayer.currentStation?.id == station.id) {
          if (url != oldUrl) {
            radioPlayer.play(station).catchError((_) {});
          } else if (name != oldName) {
            radioPlayer.refreshMediaItem();
          }
        }

        if (!sheetContext.mounted) return;
        Navigator.pop(sheetContext);
        showOverlay(sheetContext, caption: 'Station updated');
      } catch (_) {
        if (!sheetContext.mounted) return;
        showOverlay(
          sheetContext,
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
          const SizedBox(height: 8),
          FormSwitch(
            label: 'Accessible to all users',
            value: isPublic,
            onChanged: (value) => setState(() => isPublic = value),
          ),
        ],
      );
    },
  );
}

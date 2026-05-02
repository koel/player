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
    onSubmit: () async {
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

        // If we just edited the station that's currently on air, the
        // player is still streaming the old URL (its setUrl was called
        // at play time). Restart the stream when the URL changed;
        // otherwise just refresh the OS media-session metadata so the
        // lock screen / notification picks up the new name.
        if (radioPlayer.currentStation?.id == station.id) {
          if (url != oldUrl) {
            radioPlayer.play(station).catchError((_) {});
          } else if (name != oldName) {
            radioPlayer.refreshMediaItem();
          }
        }

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

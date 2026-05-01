import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/screens/edit_radio_station_sheet.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Shows the long-press context menu for a radio station — Edit and/or
/// Delete, gated on [RadioStation.canEdit] / [RadioStation.canDelete].
///
/// Returns immediately when neither permission is granted (no haptic,
/// no menu). Otherwise fires a medium haptic and opens the menu at
/// [position] in global screen coordinates.
///
/// Pass [onUpdated] if the caller needs to rebuild after a successful
/// edit (the provider mutates the station in place but doesn't notify
/// individual row widgets).
Future<void> showRadioStationActionsMenu(
  BuildContext context, {
  required RadioStation station,
  required Offset position,
  VoidCallback? onUpdated,
}) async {
  final canEdit = station.canEdit;
  final canDelete = station.canDelete;
  if (!canEdit && !canDelete) return;

  HapticFeedback.mediumImpact();

  final selected = await showFrostedContextMenu<String>(
    context: context,
    position: position,
    items: [
      if (canEdit)
        const FrostedMenuItem(
          value: 'edit',
          icon: CupertinoIcons.pencil,
          label: 'Edit',
        ),
      if (canDelete)
        const FrostedMenuItem(
          value: 'delete',
          icon: CupertinoIcons.trash,
          label: 'Delete',
          destructive: true,
        ),
    ],
  );

  if (!context.mounted) return;

  switch (selected) {
    case 'edit':
      await showEditRadioStationDialog(context, station: station);
      onUpdated?.call();
      break;
    case 'delete':
      await _confirmAndDelete(context, station: station);
      break;
  }
}

Future<void> _confirmAndDelete(
  BuildContext context, {
  required RadioStation station,
}) async {
  final confirmed = await showCupertinoDialog<bool>(
    context: context,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: const Text('Delete station?'),
      content: Text('Delete "${station.name}"? This cannot be undone.'),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;
  if (!context.mounted) return;

  await context.read<RadioStationProvider>().remove(station);
  if (context.mounted) showOverlay(context, caption: 'Station deleted');
}

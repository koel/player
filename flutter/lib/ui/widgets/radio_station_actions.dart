import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// Asks the user to confirm deleting [station]. Returns `true` on
/// confirm, `false` on cancel.
Future<bool> confirmDeleteRadioStation(
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
  return confirmed == true;
}

/// Calls [RadioStationProvider.remove] (fire-and-forget, locally
/// optimistic) and shows a 'Station deleted' overlay.
void deleteRadioStationWithFeedback(
  BuildContext context, {
  required RadioStation station,
}) {
  context.read<RadioStationProvider>().remove(station);
  showOverlay(context, caption: 'Station deleted');
}

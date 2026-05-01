import 'package:app/models/models.dart';
import 'package:app/ui/screens/edit_artist_sheet.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

/// Shows the long-press context menu for an artist — currently only Edit
/// (the koel API doesn't expose a delete endpoint for artists).
///
/// Returns immediately when the user isn't permitted to edit (no
/// haptic, no menu). Otherwise fires a medium haptic and opens the
/// menu at [position] in global screen coordinates.
///
/// Pass [onUpdated] if the caller needs to rebuild after a successful
/// edit (the provider mutates the artist in place but doesn't notify
/// individual row/card widgets).
Future<void> showArtistActionsMenu(
  BuildContext context, {
  required Artist artist,
  required Offset position,
  VoidCallback? onUpdated,
}) async {
  if (!artist.canEdit) return;

  HapticFeedback.mediumImpact();

  final selected = await showFrostedContextMenu<String>(
    context: context,
    position: position,
    items: const [
      FrostedMenuItem(
        value: 'edit',
        icon: CupertinoIcons.pencil,
        label: 'Edit',
      ),
    ],
  );

  if (!context.mounted) return;

  if (selected == 'edit') {
    await showEditArtistDialog(context, artist: artist);
    if (!context.mounted) return;
    onUpdated?.call();
  }
}

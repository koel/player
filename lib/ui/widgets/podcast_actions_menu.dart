import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Shows the long-press context menu for a podcast — currently only
/// Unsubscribe. Unlike the other resource menus, this one isn't gated
/// on a server permission: a user can always unsubscribe from a
/// podcast they're subscribed to.
Future<void> showPodcastActionsMenu(
  BuildContext context, {
  required Podcast podcast,
  required Offset position,
}) async {
  HapticFeedback.mediumImpact();

  final selected = await showFrostedContextMenu<String>(
    context: context,
    position: position,
    items: const [
      FrostedMenuItem(
        value: 'unsubscribe',
        icon: CupertinoIcons.minus_circle,
        label: 'Unsubscribe',
        destructive: true,
      ),
    ],
  );

  if (!context.mounted) return;

  if (selected == 'unsubscribe') {
    await _confirmAndUnsubscribe(context, podcast: podcast);
  }
}

Future<void> _confirmAndUnsubscribe(
  BuildContext context, {
  required Podcast podcast,
}) async {
  final confirmed = await showCupertinoDialog<bool>(
    context: context,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: const Text('Unsubscribe?'),
      content: Text('Unsubscribe from "${podcast.title}"?'),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Unsubscribe'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;
  if (!context.mounted) return;

  try {
    await context.read<PodcastProvider>().unsubscribePodcast(podcast);
    if (context.mounted) showOverlay(context, caption: 'Unsubscribed');
  } catch (_) {
    if (context.mounted) {
      showOverlay(
        context,
        caption: 'Error',
        message: 'Could not unsubscribe.',
        icon: CupertinoIcons.exclamationmark_triangle,
      );
    }
  }
}

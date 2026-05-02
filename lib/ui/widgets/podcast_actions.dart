import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// Asks the user to confirm unsubscribing from [podcast]. Returns `true`
/// on confirm, `false` on cancel. Does not call any network-backed code.
Future<bool> confirmUnsubscribePodcast(
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
  return confirmed == true;
}

/// Calls [PodcastProvider.unsubscribePodcast] and shows a success or
/// error overlay. The caller is responsible for confirming with the
/// user beforehand (see [confirmUnsubscribePodcast]).
Future<void> unsubscribePodcastWithFeedback(
  BuildContext context, {
  required Podcast podcast,
}) async {
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

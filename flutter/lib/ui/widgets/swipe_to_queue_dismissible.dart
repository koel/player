import 'package:app/main.dart';
import 'package:app/models/models.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SwipeToQueueDismissible extends StatefulWidget {
  final Key dismissibleKey;
  final Future<List<Playable>> Function() fetchSongs;
  final Widget child;

  const SwipeToQueueDismissible({
    Key? key,
    required this.dismissibleKey,
    required this.fetchSongs,
    required this.child,
  }) : super(key: key);

  @override
  State<SwipeToQueueDismissible> createState() =>
      _SwipeToQueueDismissibleState();
}

class _SwipeToQueueDismissibleState extends State<SwipeToQueueDismissible> {
  @override
  Widget build(BuildContext context) {
    return Dismissible(
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        try {
          final songs = await widget.fetchSongs();
          if (!mounted) return false;

          if (songs.isNotEmpty) {
            for (final song in songs) {
              await audioHandler.queueToBottom(song);
            }
            if (mounted) showOverlay(context, caption: 'Queued');
          }
        } catch (e) {
          if (mounted) {
            showOverlay(
              context,
              caption: 'Error',
              icon: CupertinoIcons.exclamationmark_triangle,
            );
          }
        }
        return false;
      },
      background: Container(
        alignment: AlignmentDirectional.centerStart,
        color: Colors.green,
        child: const Padding(
          padding: EdgeInsets.only(left: 28),
          child: Icon(CupertinoIcons.text_badge_plus),
        ),
      ),
      key: widget.dismissibleKey,
      child: widget.child,
    );
  }
}

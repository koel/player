import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The background revealed by an `endToStart` swipe (swipe-left) on a
/// list row that triggers a destructive action — e.g. delete, unsubscribe.
///
/// Sized to fill the row, with the trash icon and the optional [label]
/// pinned to the right edge so they show as the row slides off to the
/// left, matching iOS Mail-style swipe-to-delete.
class SwipeDestructiveBackground extends StatelessWidget {
  final String label;

  const SwipeDestructiveBackground({Key? key, this.label = 'Delete'})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CupertinoColors.systemRed,
      alignment: AlignmentDirectional.centerEnd,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(CupertinoIcons.trash, color: Colors.white),
        ],
      ),
    );
  }
}

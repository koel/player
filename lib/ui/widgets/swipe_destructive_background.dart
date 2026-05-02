import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The background revealed by an `endToStart` swipe (swipe-left) on a
/// list row that triggers a destructive action — e.g. delete, unsubscribe.
///
/// Sized to fill the row, with a trash icon pinned to the right edge so
/// it shows as the row slides off to the left, matching iOS Mail-style
/// swipe-to-delete.
class SwipeDestructiveBackground extends StatelessWidget {
  const SwipeDestructiveBackground({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CupertinoColors.systemRed,
      alignment: AlignmentDirectional.centerEnd,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: const Icon(CupertinoIcons.trash, color: Colors.white),
    );
  }
}

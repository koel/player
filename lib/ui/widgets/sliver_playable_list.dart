import 'package:app/constants/constants.dart';
import 'package:app/main.dart';
import 'package:app/models/models.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SliverPlayableList extends StatelessWidget {
  final List<Playable> playables;
  final PlayableListContext listContext;
  final Widget dismissIcon;
  final Function(Playable playable)? onDismissed;

  SliverPlayableList({
    Key? key,
    required this.playables,
    this.listContext = PlayableListContext.other,
    this.onDismissed,
    this.dismissIcon = const Icon(CupertinoIcons.delete),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, int index) {
          return onDismissed == null
              ? PlayableRow(
                  playable: playables[index],
                  listContext: listContext,
                )
              : Dismissible(
                  direction: DismissDirection.horizontal,
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.endToStart) {
                      onDismissed?.call(playables[index]);
                      return true;
                    }

                    await audioHandler.queueAfterCurrent(playables[index]);

                    showOverlay(
                      context,
                      icon: CupertinoIcons.arrow_right_circle_fill,
                      caption: 'Queued',
                      message: 'To be played next.',
                    );

                    return false;
                  },
                  background: Container(
                    alignment: AlignmentDirectional.centerStart,
                    color: Colors.green,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 28),
                      child: const Icon(LucideIcons.listPlus),
                    ),
                  ),
                  secondaryBackground: Container(
                    alignment: AlignmentDirectional.centerEnd,
                    color: AppColors.red,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 28),
                      child: dismissIcon,
                    ),
                  ),
                  key: ValueKey(playables[index]),
                  child: PlayableRow(
                    playable: playables[index],
                    listContext: listContext,
                  ),
                );
        },
        childCount: playables.length,
      ),
    );
  }
}

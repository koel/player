import 'package:app/constants/constants.dart';
import 'package:app/models/models.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';

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
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => onDismissed?.call(playables[index]),
                  background: Container(
                    alignment: AlignmentDirectional.centerEnd,
                    color: AppColors.highlightAccent,
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

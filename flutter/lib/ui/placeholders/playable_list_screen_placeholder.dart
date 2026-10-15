import 'package:app/constants/constants.dart';
import 'package:app/ui/placeholders/placeholders.dart';
import 'package:flutter/material.dart';

class PlayableListScreenPlaceholder extends StatelessWidget {
  const PlayableListScreenPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GradientPlaceholder(
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          const SliverAppBar(expandedHeight: 144),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.hPadding),
              child: Row(
                children: [
                  const CirclePlaceholder(),
                  const Spacer(),
                  const CirclePlaceholder(),
                  const SizedBox(width: 16),
                  const CirclePlaceholder(size: 58),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, __) => const PlayableRowPlaceholder(),
              childCount: 10,
            ),
          ),
        ],
      ),
    );
  }
}

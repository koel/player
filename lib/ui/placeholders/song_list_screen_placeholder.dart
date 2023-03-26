import 'package:app/ui/placeholders/placeholders.dart';
import 'package:flutter/material.dart';

class SongListScreenPlaceholder extends StatelessWidget {
  const SongListScreenPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GradientPlaceholder(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(expandedHeight: 144),
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  const RoundedButtonPlaceholder(),
                  const Spacer(),
                  const RoundedButtonPlaceholder(),
                  const SizedBox(width: 16),
                  const RoundedButtonPlaceholder(size: 58),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, __) => const SongRowPlaceholder(),
              childCount: 10,
            ),
          ),
        ],
      ),
    );
  }
}

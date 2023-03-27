import 'package:app/ui/placeholders/placeholders.dart';
import 'package:flutter/material.dart';

class AlbumScreenPlaceholder extends StatelessWidget {
  const AlbumScreenPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GradientPlaceholder(
      child: CustomScrollView(
        slivers: [
          const SliverAppBar(expandedHeight: 96),
          SliverToBoxAdapter(child: Container(height: 16.0)),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, __) => const AlbumRowPlaceholder(),
              childCount: 30,
            ),
          ),
        ],
      ),
    );
  }
}

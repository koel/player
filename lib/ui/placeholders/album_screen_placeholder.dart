import 'package:app/ui/placeholders/gradient_placeholder.dart';
import 'package:app/ui/placeholders/placeholders.dart';
import 'package:flutter/material.dart';

class AlbumScreenPlaceholder extends StatelessWidget {
  const AlbumScreenPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GradientPlaceholder(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(expandedHeight: 96),
          SliverToBoxAdapter(child: Container(height: 16.0)),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, __) => const AlbumRowPlaceholder(),
              childCount: 10,
            ),
          ),
        ],
      ),
    );
  }
}

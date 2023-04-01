import 'package:app/ui/placeholders/artist_row_placeholder.dart';
import 'package:app/ui/placeholders/gradient_placeholder.dart';
import 'package:flutter/material.dart';

class ArtistScreenPlaceholder extends StatelessWidget {
  const ArtistScreenPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GradientPlaceholder(
      child: CustomScrollView(
        physics: NeverScrollableScrollPhysics(),
        slivers: [
          const SliverAppBar(expandedHeight: 96),
          SliverToBoxAdapter(child: Container(height: 16.0)),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, __) => const ArtistRowPlaceholder(),
              childCount: 30,
            ),
          ),
        ],
      ),
    );
  }
}

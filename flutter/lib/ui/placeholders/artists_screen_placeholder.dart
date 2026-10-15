import 'dart:math';

import 'package:app/ui/placeholders/gradient_placeholder.dart';
import 'package:flutter/material.dart';

class ArtistsScreenPlaceholder extends StatelessWidget {
  const ArtistsScreenPlaceholder({Key? key}) : super(key: key);

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

class ArtistRowPlaceholder extends StatelessWidget {
  const ArtistRowPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: Border(bottom: Divider.createBorderSide(context)),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
      title: Container(
        height: 16,
        color: Colors.white,
        margin: EdgeInsets.only(right: Random().nextInt(180).toDouble()),
      ),
    );
  }
}

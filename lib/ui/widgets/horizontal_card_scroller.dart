import 'package:app/constants/constants.dart';
import 'package:app/enums.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';

class HorizontalCardScroller extends StatelessWidget {
  final Iterable<Widget> cards;
  final String? headingText;

  const HorizontalCardScroller({
    Key? key,
    required this.cards,
    this.headingText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final headingText = this.headingText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (headingText != null)
          Padding(
            padding: const EdgeInsets.only(
              left: AppDimensions.hPadding,
            ),
            child: Heading5(text: headingText),
          ),
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.hPadding,
          ),
          scrollDirection: Axis.horizontal,
          child: Wrap(
            spacing: AppDimensions.hPadding,
            children: cards.toList(),
          ),
        ),
      ],
    );
  }
}

class PlaceholderCard extends StatelessWidget {
  final IconData icon;
  final void Function()? onPressed;
  final bool circular;

  const PlaceholderCard({
    Key? key,
    required this.icon,
    this.onPressed,
    this.circular = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dimension = AlbumArtistThumbnail.dimensionForSize(ThumbnailSize.md);

    return Card(
      shape: circular
          ? const CircleBorder()
          : SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius(
                cornerRadius: AlbumArtistThumbnail.borderRadiusForSize(
                  ThumbnailSize.md,
                ),
                cornerSmoothing: .8,
              ),
            ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox.square(
        dimension: dimension,
        child: ElevatedButton(
          onPressed: onPressed,
          child: Icon(icon, size: 32),
          style: ElevatedButton.styleFrom(
            backgroundColor: highlightColor,
          ),
        ),
      ),
    );
  }
}

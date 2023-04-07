import 'package:app/constants/dimensions.dart';
import 'package:app/ui/widgets/typography.dart';
import 'package:flutter/cupertino.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (headingText != null)
          Padding(
            padding:
                const EdgeInsets.only(left: AppDimensions.horizontalPadding),
            child: Heading5(text: headingText!),
          ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ...cards.expand(
                (card) => <Widget>[
                  const SizedBox(width: AppDimensions.horizontalPadding),
                  card,
                ],
              ),
              const SizedBox(width: AppDimensions.horizontalPadding),
            ],
          ),
        ),
      ],
    );
  }
}

class PlaceholderCard extends StatelessWidget {
  final IconData icon;
  final void Function()? onPressed;

  const PlaceholderCard({
    Key? key,
    required this.icon,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 144,
      width: 144,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          border: Border.all(color: Colors.white10),
        ),
        child: IconButton(
          onPressed: onPressed,
          iconSize: 32,
          icon: Icon(icon),
        ),
      ),
    );
  }
}

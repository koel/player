import 'package:app/constants/constants.dart';
import 'package:app/ui/placeholders/placeholders.dart';
import 'package:flutter/material.dart';

class HorizontalCardScrollerPlaceholder extends StatelessWidget {
  const HorizontalCardScrollerPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(
            left: AppDimensions.horizontalPadding,
            bottom: 12.0,
          ),
          child: Container(
            height: 24,
            width: 100,
            color: Colors.white,
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List<Widget>.generate(5, (_) => const CardPlaceholder())
                .expand<Widget>(
                  (card) => [
                    const SizedBox(width: AppDimensions.horizontalPadding),
                    card,
                  ],
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

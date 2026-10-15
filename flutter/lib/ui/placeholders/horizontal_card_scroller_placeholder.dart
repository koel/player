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
            left: AppDimensions.hPadding,
            bottom: 12.0,
          ),
          child: Container(
            height: 24,
            width: 100,
            color: Colors.white,
          ),
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.hPadding,
          ),
          physics: NeverScrollableScrollPhysics(),
          scrollDirection: Axis.horizontal,
          child: Wrap(
            spacing: AppDimensions.hPadding,
            children: List<Widget>.generate(5, (_) => const CardPlaceholder()),
          ),
        ),
      ],
    );
  }
}

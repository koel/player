import 'package:app/constants/constants.dart';
import 'package:app/ui/placeholders/placeholders.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomeScreenPlaceholder extends StatelessWidget {
  const HomeScreenPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GradientPlaceholder(
      child: CustomScrollView(
        physics: NeverScrollableScrollPhysics(),
        slivers: <Widget>[
          const CupertinoSliverNavigationBar(
            largeTitle: Text(''),
            trailing: CirclePlaceholder(size: 24),
          ),
          SliverList(
            delegate: SliverChildListDelegate.fixed([
              const SizedBox(height: 32.0),
              const SongListWithHeadingPlaceholder(),
              const SizedBox(height: 16.0),
              const HorizontalCardScrollerPlaceholder(),
              const SizedBox(height: 32.0),
              const HorizontalCardScrollerPlaceholder(),
              const SizedBox(height: 32.0),
              const HorizontalCardScrollerPlaceholder(),
            ]),
          ),
        ],
      ),
    );
  }
}

class SongListWithHeadingPlaceholder extends StatelessWidget {
  const SongListWithHeadingPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.hPadding / 2,
        vertical: 8.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 32,
            width: 144,
            color: Colors.white,
            margin: const EdgeInsets.only(left: 8.0),
          ),
          ...List<Widget>.generate(4, (_) => const PlayableRowPlaceholder()),
        ],
      ),
    );
  }
}

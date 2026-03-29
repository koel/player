import 'package:app/constants/constants.dart';
import 'package:app/models/models.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/material.dart';

Widget? backgroundImageFromPlayables(List<Playable> playables) {
  final candidates = playables.where((p) => p.hasCustomImage).toList();
  if (candidates.isEmpty) return null;

  candidates.shuffle();
  final playable = candidates.first;

  return SizedBox.expand(
    child: DecoratedBox(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: playable.image,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      ),
    ),
  );
}

class AppBar extends StatelessWidget {
  final String headingText;
  final Widget? backgroundImage;
  final List<Widget> actions;

  const AppBar({
    Key? key,
    required this.headingText,
    this.backgroundImage,
    this.actions = const [],
  }) : super(key: key);

  static final Widget _defaultBackground = SizedBox.expand(
    child: DecoratedBox(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppImages.defaultImageAssetName),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final backgroundImage = this.backgroundImage ?? _defaultBackground;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 290,
      actions: actions,
      backgroundColor: Colors.transparent,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final topPadding = MediaQuery.of(context).padding.top;
          final collapsedHeight = topPadding + kToolbarHeight;
          final t = ((290 + topPadding - constraints.maxHeight) /
                  (290 + topPadding - collapsedHeight))
              .clamp(0.0, 1.0);

          return Stack(
            children: [
              // Collapsed bar background — only visible when pinned
              Opacity(
                key: const Key('appBarCollapsedBackground'),
                opacity: t,
                child: Container(
                  height: collapsedHeight,
                  color: const Color.fromRGBO(25, 0, 64, 0.95),
                ),
              ),
              FlexibleSpaceBar(
        expandedTitleScale: 1.3,
        titlePadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        title: MarqueeText(
          text: headingText,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        background: ShaderMask(
                key: const Key('appBarBackgroundMask'),
                shaderCallback: (bounds) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.6, 1.0],
                    colors: [
                      Colors.white,
                      Colors.white,
                      Colors.transparent,
                    ],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    1.2, 0, 0, 0, -20,
                    0, 1.2, 0, 0, -20,
                    0, 0, 1.2, 0, -20,
                    0, 0, 0, 1, 0,
                  ]),
                  child: backgroundImage,
                ),
              ),
      ),
            ],
          );
        },
      ),
    );
  }
}

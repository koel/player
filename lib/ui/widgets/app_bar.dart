import 'package:app/constants/constants.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final backgroundImage = this.backgroundImage;

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
        background: backgroundImage != null
            ? ShaderMask(
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
                child: backgroundImage,
              )
            : null,
      ),
            ],
          );
        },
      ),
    );
  }
}

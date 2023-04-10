import 'package:flutter/material.dart';
import 'package:scrolls_to_top/scrolls_to_top.dart' as Base;

class ScrollsToTop extends StatelessWidget {
  final Widget child;
  final ScrollController? scrollController;
  final Base.ScrollsToTopCallback? onScrollsToTop;

  const ScrollsToTop({
    Key? key,
    required this.child,
    this.onScrollsToTop,
    this.scrollController,
  }) : super(key: key);

  Widget build(BuildContext context) {
    var controller = scrollController ?? PrimaryScrollController.of(context);

    return Base.ScrollsToTop(
      child: child,
      onScrollsToTop: onScrollsToTop ??
          (event) async {
            controller.animateTo(
              0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
            );
          },
    );
  }
}

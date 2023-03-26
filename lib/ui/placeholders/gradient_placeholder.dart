import 'package:app/constants/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:shimmer/shimmer.dart';

class GradientPlaceholder extends StatelessWidget {
  final Widget child;

  const GradientPlaceholder({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.white.withOpacity(.1),
      highlightColor: AppColors.white.withOpacity(.2),
      child: child,
    );
  }
}

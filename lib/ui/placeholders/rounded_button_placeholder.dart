import 'package:app/constants/constants.dart';
import 'package:flutter/cupertino.dart';

class RoundedButtonPlaceholder extends StatelessWidget {
  final double size;

  const RoundedButtonPlaceholder({
    Key? key,
    this.size = 32,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

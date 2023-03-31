import 'package:app/constants/colors.dart';
import 'package:flutter/material.dart';

class PullToRefresh extends StatefulWidget {
  const PullToRefresh({
    Key? key,
    required this.child,
    required this.onRefresh,
  }) : super(key: key);

  final Widget child;
  final Future<void> Function() onRefresh;

  @override
  _PullToRefreshState createState() => _PullToRefreshState();
}

class _PullToRefreshState extends State<PullToRefresh> {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      backgroundColor: AppColors.highlight.withOpacity(.8),
      onRefresh: widget.onRefresh,
      color: Colors.white,
      displacement: 0,
      edgeOffset: 60,
      child: widget.child,
    );
  }
}

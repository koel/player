import 'package:flutter/material.dart';

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration pauseDuration;
  final Duration scrollDuration;

  const MarqueeText({
    Key? key,
    required this.text,
    this.style,
    this.pauseDuration = const Duration(seconds: 2),
    this.scrollDuration = const Duration(seconds: 4),
  }) : super(key: key);

  @override
  _MarqueeTextState createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  bool _needsScroll = false;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndAnimate());
  }

  @override
  void didUpdateWidget(covariant MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndAnimate());
    }
  }

  void _checkAndAnimate() {
    if (!mounted || !_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final needsScroll = maxScroll > 0;

    if (needsScroll != _needsScroll) {
      setState(() => _needsScroll = needsScroll);
    }

    if (_needsScroll && !_isAnimating) {
      _startAnimation();
    }
  }

  Future<void> _startAnimation() async {
    _isAnimating = true;

    while (mounted && _needsScroll && _scrollController.hasClients) {
      await Future.delayed(widget.pauseDuration);
      if (!mounted || !_scrollController.hasClients) break;

      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll <= 0) break;

      // Scroll to end
      await _scrollController.animateTo(
        maxScroll,
        duration: widget.scrollDuration,
        curve: Curves.easeInOut,
      );

      await Future.delayed(widget.pauseDuration);
      if (!mounted || !_scrollController.hasClients) break;

      // Scroll back to start
      await _scrollController.animateTo(
        0,
        duration: widget.scrollDuration,
        curve: Curves.easeInOut,
      );
    }

    _isAnimating = false;
  }

  @override
  void dispose() {
    _isAnimating = false;
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.text,
        maxLines: 1,
        softWrap: false,
        style: widget.style,
      ),
    );

    if (!_needsScroll) return child;

    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: [0.0, 0.08, 0.92, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }
}

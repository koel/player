import 'dart:async';

import 'package:app/ui/widgets/widgets.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MessageOverlay extends StatefulWidget {
  final String? caption;
  final String? message;
  final IconData icon;
  final Color iconColor;
  final Duration timeOut;
  final void Function()? onDismiss;

  const MessageOverlay({
    Key? key,
    this.caption,
    this.message,
    this.icon = CupertinoIcons.check_mark_circled_solid,
    this.iconColor = Colors.white30,
    this.timeOut = const Duration(seconds: 2),
    this.onDismiss,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MessageOverlayState();
}

class _MessageOverlayState extends State<MessageOverlay> {
  bool _visible = false;
  final Duration _animationDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();

    setState(() => _visible = true);
    HapticFeedback.lightImpact();
    Future.delayed(widget.timeOut, hideOverlay);
  }

  void hideOverlay() {
    if (!_visible) return;
    setState(() => _visible = false);
    Future.delayed(_animationDuration, widget.onDismiss);
  }

  @override
  Widget build(BuildContext context) {
    final caption = widget.caption;
    final message = widget.message;

    return GestureDetector(
      onTap: hideOverlay,
      behavior: HitTestBehavior.translucent,
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 130, left: 32, right: 32),
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: _animationDuration,
              child: Container(
                decoration: ShapeDecoration(
                  shape: SmoothRectangleBorder(
                    side: BorderSide(color: Colors.white24),
                    borderRadius: SmoothBorderRadius(
                      cornerRadius: 16,
                      cornerSmoothing: .5,
                    ),
                  ),
                ),
                child: ClipSmoothRect(
                  radius: SmoothBorderRadius(
                    cornerRadius: 16,
                    cornerSmoothing: .5,
                  ),
                  child: FrostedGlassBackground(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            widget.icon,
                            size: 24,
                            color: widget.iconColor,
                          ),
                          if (caption != null || message != null)
                            const SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                if (caption != null)
                                  Text(
                                    caption,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                if (message != null)
                                  Text(
                                    message,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: Colors.white60),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void showOverlay(
  BuildContext context, {
  String? caption,
  String? message,
  IconData icon = CupertinoIcons.check_mark_circled_solid,
  Color iconColor = Colors.white30,
  Duration timeOut = const Duration(seconds: 2),
}) {
  late OverlayEntry _entry;

  _entry = OverlayEntry(builder: (_) {
    return MessageOverlay(
      caption: caption,
      message: message,
      icon: icon,
      iconColor: iconColor,
      timeOut: timeOut,
      onDismiss: () => _entry.remove(),
    );
  });

  Navigator.of(context).overlay?.insert(_entry);
}

import 'dart:async';

import 'package:app/ui/widgets/widgets.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
      child: Scaffold(
        body: SafeArea(
          child: Align(
            alignment: Alignment.center,
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: _animationDuration,
              child: Container(
                width: 256.0,
                height: 256.0,
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  shape: SmoothRectangleBorder(
                    borderRadius: SmoothBorderRadius(
                      cornerRadius: 24,
                      cornerSmoothing: .5,
                    ),
                  ),
                ),
                child: FrostedGlassBackground(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            widget.icon,
                            size: 80.0,
                            color: widget.iconColor,
                          ),
                          if (caption != null) ...<Widget>[
                            const SizedBox(height: 16.0),
                            Text(
                              caption,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(color: Colors.white60),
                            ),
                          ],
                          if (message != null) ...<Widget>[
                            const SizedBox(height: 16.0),
                            Text(
                              message,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: Colors.white60),
                            ),
                          ]
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

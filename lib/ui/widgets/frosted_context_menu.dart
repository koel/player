import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// One row in a [showFrostedContextMenu] popup.
class FrostedMenuItem<T> {
  /// The value returned from [showFrostedContextMenu] when this row is
  /// tapped.
  final T value;

  /// The visible label text.
  final String label;

  /// An optional leading icon. When `null`, the row renders label-only.
  final IconData? icon;

  /// When `true`, the row renders in `CupertinoColors.systemRed` to
  /// signal a destructive action (e.g., Delete).
  final bool destructive;

  const FrostedMenuItem({
    required this.value,
    required this.label,
    this.icon,
    this.destructive = false,
  });
}

/// Shows a translucent dark menu at [position] (global screen coords).
///
/// Backed by an [OverlayEntry] (not a route) so that the inner
/// [BackdropFilter] can blur the content underneath — a route-based
/// approach can introduce compositing isolation that disables the blur.
///
/// Returns the [FrostedMenuItem.value] of the tapped row, or `null` if
/// the user dismissed by tapping outside.
Future<T?> showFrostedContextMenu<T>({
  required BuildContext context,
  required Offset position,
  required List<FrostedMenuItem<T>> items,
}) {
  final completer = Completer<T?>();
  late OverlayEntry entry;

  void close(T? value) {
    if (!completer.isCompleted) completer.complete(value);
    entry.remove();
  }

  entry = OverlayEntry(
    builder: (_) => _FrostedContextMenu<T>(
      anchor: position,
      items: items,
      onSelect: (value) => close(value),
      onDismiss: () => close(null),
    ),
  );

  Overlay.of(context).insert(entry);
  return completer.future;
}

class _FrostedContextMenu<T> extends StatelessWidget {
  final Offset anchor;
  final List<FrostedMenuItem<T>> items;
  final ValueChanged<T> onSelect;
  final VoidCallback onDismiss;

  const _FrostedContextMenu({
    Key? key,
    required this.anchor,
    required this.items,
    required this.onSelect,
    required this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dividerColor =
        DividerTheme.of(context).color ?? Theme.of(context).dividerColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Estimate to keep the menu inside the viewport. The menu's
        // actual width is decided by IntrinsicWidth + minWidth.
        const estimatedWidth = 180.0;
        final estimatedHeight = items.length * 36.0 + 12;

        var left = anchor.dx;
        var top = anchor.dy;
        if (left + estimatedWidth > constraints.maxWidth) {
          left = constraints.maxWidth - estimatedWidth - 8;
        }
        if (top + estimatedHeight > constraints.maxHeight) {
          top = constraints.maxHeight - estimatedHeight - 8;
        }
        if (left < 8) left = 8;
        if (top < 8) top = 8;

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onDismiss,
              ),
            ),
            Positioned(
              left: left,
              top: top,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: dividerColor),
                ),
                position: DecorationPosition.foreground,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.25),
                      child: Material(
                        type: MaterialType.transparency,
                        child: IntrinsicWidth(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 144),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: items
                                    .map((item) => _FrostedMenuRow<T>(
                                          item: item,
                                          onTap: () => onSelect(item.value),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FrostedMenuRow<T> extends StatelessWidget {
  final FrostedMenuItem<T> item;
  final VoidCallback onTap;

  const _FrostedMenuRow({
    Key? key,
    required this.item,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color =
        item.destructive ? CupertinoColors.systemRed : Colors.white;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        child: Row(
          children: [
            if (item.icon != null) ...[
              Icon(item.icon, size: 16, color: color),
              const SizedBox(width: 8),
            ],
            Text(item.label, style: TextStyle(color: color, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

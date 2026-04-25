import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A vertically-stacked icon + label button used in the row of quick
/// actions at the top of the [PlayableActionSheet].
///
/// Designed to sit inside an [IntrinsicHeight] [Row] so siblings share
/// the same height. Triggers [HapticFeedback.mediumImpact] on tap to
/// match the rest of the app's haptic conventions.
class PlayableQuickAction extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onTap;
  final bool enabled;

  const PlayableQuickAction({
    Key? key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = enabled ? Colors.white : Colors.white30;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled
              ? () {
                  HapticFeedback.mediumImpact();
                  onTap();
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconTheme(
                  data: IconThemeData(color: color),
                  child: icon,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A 1px-wide vertical divider with a transparent → divider-color →
/// transparent gradient. Sized to fill the parent's height.
class PlayableQuickActionDivider extends StatelessWidget {
  const PlayableQuickActionDivider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dividerColor =
        DividerTheme.of(context).color ?? Theme.of(context).dividerColor;

    return Container(
      width: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            dividerColor,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

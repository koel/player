import 'package:app/main.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/screens/screens.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:app/utils/api_request.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.authUser;

    return Scaffold(
      body: GradientDecoratedContainer(
        child: SafeArea(
          child: ListView(
            children: [
              const SizedBox(height: 16),
              // User info header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(CupertinoIcons.back),
                    ),
                    const SizedBox(width: 8),
                    ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: user.avatar.url,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          width: 48,
                          height: 48,
                          color: Colors.white12,
                          child: const Icon(CupertinoIcons.person_fill),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            user.email,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Settings section
              _SectionHeader(title: 'Playback'),
              _SwitchTile(
                title: 'Continuous Playback',
                subtitle:
                    'Playing a song triggers continuous playback of the '
                    'entire playlist, album, or folder.',
                value: user.continuousPlayback,
                onChanged: (value) async {
                  setState(() => user.continuousPlayback = value);
                  await _updatePreference(
                      'continuous_playback', value);
                },
              ),
              _SliderTile(
                title: 'Crossfade Duration',
                subtitle: user.crossfadeDuration == 0
                    ? 'Off'
                    : '${user.crossfadeDuration}s',
                value: user.crossfadeDuration.toDouble(),
                min: 0,
                max: 15,
                divisions: 15,
                onChanged: (value) async {
                  final intValue = value.round();
                  setState(() => user.crossfadeDuration = intValue);
                  await _updatePreference(
                      'crossfade_duration', intValue);
                },
              ),
              const SizedBox(height: 24),
              // Actions section
              _SectionHeader(title: 'Actions'),
              _ActionTile(
                title: 'Clear Downloads',
                icon: CupertinoIcons.trash,
                onTap: () => _confirmClearDownloads(context),
              ),
              _ActionTile(
                title: 'Log Out',
                icon: CupertinoIcons.square_arrow_right,
                isDestructive: true,
                onTap: () => _confirmLogout(context),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updatePreference(String key, dynamic value) async {
    try {
      await patch('me/preferences', data: {
        'key': key,
        'value': value,
      });
    } catch (_) {}
  }

  void _confirmClearDownloads(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Clear Downloads?'),
        content: const Text('All downloaded songs will be removed.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Clear'),
            onPressed: () {
              context.read<DownloadProvider>().clear();
              Navigator.pop(context);
              showOverlay(context, caption: 'Downloads cleared');
            },
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Log out?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Confirm'),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              await audioHandler.cleanUpUponLogout();
              Navigator.of(
                context,
                rootNavigator: true,
              ).pushNamedAndRemoveUntil(
                LoginScreen.routeName,
                (_) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white38,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white54, fontSize: 13),
      ),
      trailing: CupertinoSwitch(value: value, onChanged: onChanged),
    );
  }
}

class _SliderTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
      subtitle: CupertinoSlider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionTile({
    required this.title,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? CupertinoColors.destructiveRed : null;

    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white54),
      title: Text(title, style: color != null ? TextStyle(color: color) : null),
      trailing: const Icon(
        CupertinoIcons.chevron_forward,
        size: 16,
        color: Colors.white24,
      ),
      onTap: onTap,
    );
  }
}

import 'package:app/main.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/app.dart';
import 'package:app/ui/screens/screens.dart';
import 'package:app/utils/preferences.dart' as preferences;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum ProfileAvatarMenuItems {
  toggleTheme,
  clearDownloads,
  logout,
}

class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({Key? key}) : super(key: key);

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  void logout(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Log out?'),
          actions: <Widget>[
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              child: const Text('Confirm'),
              isDestructiveAction: true,
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                await audioHandler.cleanUpUponLogout();
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).pushNamedAndRemoveUntil(LoginScreen.routeName, (_) => false);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final downloads = context.read<DownloadProvider>();

    return PopupMenuButton<ProfileAvatarMenuItems>(
      onSelected: (item) {
        switch (item) {
          case ProfileAvatarMenuItems.toggleTheme:
            setState(() {
              preferences.isDarkTheme = !preferences.isDarkTheme;
              appKey.currentState?.refreshTheme();
            });
            break;
          case ProfileAvatarMenuItems.clearDownloads:
            downloads.clear();
            break;
          case ProfileAvatarMenuItems.logout:
            logout(context);
            break;
        }
      },
      child: const Icon(CupertinoIcons.person_alt_circle, size: 24),
      offset: const Offset(0, 32),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: ProfileAvatarMenuItems.toggleTheme,
          child: Row(
            children: [
              Icon(
                preferences.isDarkTheme
                    ? CupertinoIcons.sun_max_fill
                    : CupertinoIcons.moon_fill,
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(preferences.isDarkTheme
                  ? 'Switch to Colorful'
                  : 'Switch to Black'),
            ],
          ),
        ),
        const PopupMenuDivider(height: .5),
        const PopupMenuItem(
          value: ProfileAvatarMenuItems.clearDownloads,
          child: Text('Clear downloads'),
        ),
        const PopupMenuDivider(height: .5),
        const PopupMenuItem(
          value: ProfileAvatarMenuItems.logout,
          child: Text('Log out'),
        ),
      ],
    );
  }
}

import 'package:app/main.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/screens/screens.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum ProfileAvatarMenuItems {
  clearDownloads,
  logout,
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({Key? key}) : super(key: key);

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

import 'package:app/providers/providers.dart';
import 'package:app/ui/screens/login.dart';
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
    AuthProvider auth = context.read();
    AudioProvider audio = context.read();

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
                await auth.logout();
                await audio.cleanUpUponLogout();
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
    DownloadProvider downloads = context.read();

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
      child: const Icon(
        CupertinoIcons.person_alt_circle,
        size: 24,
      ),
      offset: Offset(0, 32),
      padding: EdgeInsets.zero,
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          value: ProfileAvatarMenuItems.clearDownloads,
          child: Text('Clear downloads'),
          height: 32.0,
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: ProfileAvatarMenuItems.logout,
          child: Text('Log out'),
          height: 32.0,
        ),
      ],
    );
  }
}

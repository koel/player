import 'dart:io';

import 'package:app/main.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/screens/screens.dart';
import 'package:app/ui/widgets/gradient_decorated_container.dart';
import 'package:app/utils/preferences.dart' as preferences;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

enum ProfileAvatarMenuItems {
  changeBackground,
  resetBackground,
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

  Future<void> _changeBackground() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final ext = path.extension(picked.path);
    final id = const Uuid().v4();
    final dest = File('${appDir.path}/background_$id$ext');

    // Remove the old custom background file
    final oldPath = preferences.backgroundImagePath;
    if (oldPath != null) {
      try {
        await File(oldPath).delete();
      } catch (_) {}
    }

    await File(picked.path).copy(dest.path);

    preferences.backgroundImagePath = dest.path;
    backgroundImageNotifier.value = dest.path;
  }

  void _resetBackground() {
    preferences.backgroundImagePath = null;
    backgroundImageNotifier.value = null;
  }

  @override
  Widget build(BuildContext context) {
    final downloads = context.read<DownloadProvider>();
    final hasCustomBackground = preferences.backgroundImagePath != null;

    return PopupMenuButton<ProfileAvatarMenuItems>(
      onSelected: (item) {
        switch (item) {
          case ProfileAvatarMenuItems.changeBackground:
            _changeBackground();
            break;
          case ProfileAvatarMenuItems.resetBackground:
            _resetBackground();
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
        const PopupMenuItem(
          value: ProfileAvatarMenuItems.changeBackground,
          child: Text('Change background'),
        ),
        if (hasCustomBackground)
          const PopupMenuItem(
            value: ProfileAvatarMenuItems.resetBackground,
            child: Text('Reset background'),
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

import 'package:app/main.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/screens/screens.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:app/utils/route_state.dart';
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
                RouteState.clear();
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
    return Builder(
      builder: (buttonContext) => IconButton(
        icon: const Icon(CupertinoIcons.person_alt_circle, size: 24),
        onPressed: () async {
          final box = buttonContext.findRenderObject() as RenderBox?;
          final origin = box == null
              ? Offset.zero
              : box.localToGlobal(Offset.zero) + Offset(0, box.size.height);

          final selected =
              await showFrostedContextMenu<ProfileAvatarMenuItems>(
            context: buttonContext,
            position: origin,
            items: const [
              FrostedMenuItem(
                value: ProfileAvatarMenuItems.clearDownloads,
                icon: CupertinoIcons.cloud_download,
                label: 'Clear downloads',
              ),
              FrostedMenuItem(
                value: ProfileAvatarMenuItems.logout,
                icon: CupertinoIcons.square_arrow_right,
                label: 'Log out',
                destructive: true,
              ),
            ],
          );
          if (!buttonContext.mounted) return;

          switch (selected) {
            case ProfileAvatarMenuItems.clearDownloads:
              buttonContext.read<DownloadProvider>().clear();
              break;
            case ProfileAvatarMenuItems.logout:
              logout(buttonContext);
              break;
            case null:
              break;
          }
        },
      ),
    );
  }
}

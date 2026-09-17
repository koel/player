import 'package:app/constants/constants.dart';
import 'package:app/main.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/screens/login.dart';
import 'package:app/ui/screens/playable_action_sheet.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:app/utils/preferences.dart' as preferences;
import 'package:app/utils/route_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileActionSheet extends StatelessWidget {
  final User user;

  const ProfileActionSheet({Key? key, required this.user}) : super(key: key);

  void _logout(BuildContext context) {
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
    return FrostedGlassBackground(
      sigma: 40.0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      // A DecorationImage has no intrinsic size, unlike Image,
                      // so the avatar takes the height of the text next to it.
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 120),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.background,
                                  image: DecorationImage(
                                    image: user.avatar,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white54),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              preferences.host ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(indent: 16, endIndent: 16),
              ListView(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                children: <Widget>[
                  PlayableActionButton(
                    text: 'Clear Downloads',
                    icon: const Icon(
                      CupertinoIcons.cloud_download,
                      color: Colors.white30,
                    ),
                    onTap: () => context.read<DownloadProvider>().clear(),
                  ),
                  PlayableActionButton(
                    text: 'Log Out',
                    icon: const Icon(CupertinoIcons.square_arrow_right),
                    destructive: true,
                    onTap: () => _logout(context),
                    hideSheetOnTap: false,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showProfileActionSheet(
  BuildContext context, {
  required User user,
}) {
  return showModalBottomSheet<void>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    builder: (_) => ProfileActionSheet(user: user),
  );
}

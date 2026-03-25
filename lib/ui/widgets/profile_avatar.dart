import 'package:app/providers/providers.dart';
import 'package:app/ui/screens/screens.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().authUser;

    return GestureDetector(
      onTap: () => Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute(builder: (_) => const SettingsScreen()),
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: user.avatar.url,
          width: 28,
          height: 28,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => const Icon(
            CupertinoIcons.person_alt_circle,
            size: 28,
          ),
        ),
      ),
    );
  }
}

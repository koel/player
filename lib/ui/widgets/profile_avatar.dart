import 'package:app/providers/providers.dart';
import 'package:app/ui/screens/screens.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(CupertinoIcons.person_alt_circle, size: 24),
      onPressed: () => showProfileActionSheet(
        context,
        user: context.read<AuthProvider>().authUser,
      ),
    );
  }
}

import 'package:app/providers/auth_provider.dart';
import 'package:app/ui/screens/login.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OopsBox extends StatelessWidget {
  static Key retryButtonKey = UniqueKey();
  static Key logOutButtonKey = UniqueKey();

  final void Function()? onRetryButtonPressed;
  final String? message;

  const OopsBox({Key? key, this.message, this.onRetryButtonPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    AuthProvider auth = context.watch();

    return Container(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Oops!',
              style: Theme.of(context).textTheme.headline5,
            ),
            const SizedBox(height: 16),
            Text(message ?? 'Something wrong happened.'),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TextButton(
                  key: retryButtonKey,
                  onPressed: onRetryButtonPressed,
                  child: const Text('Retry'),
                ),
                TextButton(
                  key: logOutButtonKey,
                  onPressed: () async {
                    await auth.logout();
                    await Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pushNamedAndRemoveUntil(
                      LoginScreen.routeName,
                      (_) => false,
                    );
                  },
                  child: const Text(
                    'Log Out',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

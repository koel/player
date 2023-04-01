import 'package:app/constants/constants.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OopsBox extends StatelessWidget {
  static Key retryButtonKey = UniqueKey();
  static Key logOutButtonKey = UniqueKey();

  final void Function()? onRetry;
  final bool showLogOutButton;
  final String? message;

  const OopsBox({
    Key? key,
    this.message,
    this.onRetry,
    this.showLogOutButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Container(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Oops!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: message ??
                      'The request cannot be completed. '
                          'Please double-check if you are '
                          'connected to the internet.',
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (onRetry != null)
                  ElevatedButton(
                    key: retryButtonKey,
                    onPressed: onRetry,
                    child: const Text('Retry'),
                  ),
                if (showLogOutButton) ...[
                  const SizedBox(width: 8),
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
                      style: TextStyle(color: Colors.white60),
                    ),
                  ),
                ]
              ],
            )
          ],
        ),
      ),
    );
  }
}

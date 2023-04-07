import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/screens/screens.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InitialScreen extends StatefulWidget {
  static const routeName = '/';

  const InitialScreen({Key? key}) : super(key: key);

  @override
  _InitialScreenState createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> with StreamSubscriber {
  @override
  void initState() {
    super.initState();

    Connectivity().checkConnectivity().then((value) {
      if (value == ConnectivityResult.none) {
        Navigator.of(context).pushReplacementNamed(
          NoConnectionScreen.routeName,
        );
      } else {
        _resolveAuthenticatedUser();
      }
    });
  }

  Future<void> _resolveAuthenticatedUser() async {
    try {
      final user = await context.read<AuthProvider>().tryGetAuthUser();
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            user == null ? const LoginScreen() : const DataLoadingScreen(),
        transitionDuration: Duration.zero,
      ));
    } catch (e) {
      await Navigator.of(context, rootNavigator: true).pushReplacementNamed(
        LoginScreen.routeName,
      );
    }
  }

  @override
  Widget build(BuildContext context) => const ContainerWithSpinner();
}

import 'package:app/constants/strings.dart';
import 'package:app/models/user.dart';
import 'package:app/providers/auth_provider.dart';
import 'package:app/ui/screens/login.dart';
import 'package:app/ui/screens/start.dart';
import 'package:app/ui/theme_data.dart';
import 'package:app/ui/widgets/spinner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  late Future<User?> futureUser;

  @override
  void initState() {
    super.initState();
    futureUser = context.read<AuthProvider>().tryGetAuthUser();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppStrings.appName,
        theme: themeData(context),
        routes: {
          '/': (context) {
            return FutureBuilder(
              future: futureUser,
              builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                  case ConnectionState.waiting:
                    return const ContainerWithSpinner();
                  default:
                    return snapshot.data == null
                        ? const LoginScreen()
                        : const StartScreen();
                }
              },
            );
          }
        },
      ),
    );
  }
}

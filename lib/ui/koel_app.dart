import 'package:app/constants/strings.dart';
import 'package:app/models/user.dart';
import 'package:app/providers/user_provider.dart';
import 'package:app/ui/screens/start.dart';
import 'package:app/ui/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class KoelApp extends StatefulWidget {
  KoelApp({Key? key}) : super(key: key);

  @override
  _KoelAppState createState() => _KoelAppState();
}

class _KoelAppState extends State<KoelApp> {
  late Future<User?> futureUser;

  @override
  void initState() {
    super.initState();
    futureUser =
        Provider.of<UserProvider>(context, listen: false).tryGetAuthUser();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: FutureBuilder(
        future: futureUser,
        builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(child: CircularProgressIndicator()),
                ],
              );
            default:
              return snapshot.data == null ? LoginScreen() : StartScreen();
          }
        },
      ),
    );
  }
}

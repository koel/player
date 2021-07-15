import 'package:app/providers/data_provider.dart';
import 'package:app/ui/screens/main.dart';
import 'package:app/ui/widgets/spinner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DataLoadingScreen extends StatefulWidget {
  static const routeName = '/loading';

  const DataLoadingScreen({Key? key}) : super(key: key);

  @override
  _DataLoadingScreen createState() => _DataLoadingScreen();
}

class _DataLoadingScreen extends State<DataLoadingScreen> {
  late Future<void> futureData;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    futureData = context.read<DataProvider>().init(context);
  }

  @override
  Widget build(BuildContext context) {
    futureData.then((data) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainScreen(),
          transitionDuration: Duration(seconds: 2),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ZoomPageTransitionsBuilder().buildTransitions(
              null,
              context,
              animation,
              secondaryAnimation,
              child,
            );
          },
        ),
      );
    }, onError: (_) => setState(() => _hasError = true));

    return Scaffold(
      body: _hasError
          ? Container(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _hasError = false),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'Oops!',
                        style: Theme.of(context).textTheme.headline5,
                      ),
                      SizedBox(height: 16),
                      Text('Failed to load data. Tap anywhere to retry.'),
                    ],
                  ),
                ),
              ),
            )
          : const ContainerWithSpinner(),
    );
  }
}

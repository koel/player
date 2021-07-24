import 'package:app/providers/data_provider.dart';
import 'package:app/ui/screens/main.dart';
import 'package:app/ui/widgets/oops_box.dart';
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
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    context.read<DataProvider>().init(context).then((_) async {
      await Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainScreen(),
          transitionDuration: const Duration(seconds: 2),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _hasError
          ? OopsBox(
              onRetryButtonPressed: () => setState(() => _hasError = false),
            )
          : const ContainerWithSpinner(),
    );
  }
}

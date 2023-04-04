import 'package:app/providers/providers.dart';
import 'package:app/ui/screens/screens.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DataLoadingScreen extends StatefulWidget {
  static const routeName = '/loading';

  const DataLoadingScreen({Key? key}) : super(key: key);

  @override
  _DataLoadingScreen createState() => _DataLoadingScreen();
}

class _DataLoadingScreen extends State<DataLoadingScreen> {
  var _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await context.read<DataProvider>().init();
      await Navigator.of(context).pushReplacementNamed(MainScreen.routeName);
    } catch (e) {
      print(e);
      setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientDecoratedContainer(
        child: _hasError
            ? OopsBox(
                showLogOutButton: true,
                onRetry: () {
                  setState(() => _hasError = false);
                  _loadData();
                },
              )
            : const ContainerWithSpinner(),
      ),
    );
  }
}

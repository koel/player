import 'package:app/providers/providers.dart';
import 'package:app/ui/screens/root.dart';
import 'package:app/ui/widgets/oops_box.dart';
import 'package:app/ui/widgets/spinner.dart';
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
    try {
      await context.read<DataProvider>().init(context);
      await Navigator.of(context).pushReplacementNamed(RootScreen.routeName);
    } catch (e) {
      setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _hasError
          ? OopsBox(onRetryButtonPressed: () {
              setState(() => _hasError = false);
              _loadData();
            })
          : const ContainerWithSpinner(),
    );
  }
}

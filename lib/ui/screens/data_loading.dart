import 'dart:async';

import 'package:app/app_state.dart';
import 'package:app/enums.dart';
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
  static const _stillLoadingAfter = Duration(seconds: 6);
  static const _loadTimeout = Duration(seconds: 30);

  var _hasError = false;
  var _stillLoading = false;
  var _loadGeneration = 0;
  Timer? _stillLoadingTimer;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  void _cancelTimers() {
    _stillLoadingTimer?.cancel();
    _timeoutTimer?.cancel();
  }

  Future<void> _loadData() async {
    final generation = ++_loadGeneration;

    _stillLoadingTimer = Timer(_stillLoadingAfter, () {
      if (mounted) setState(() => _stillLoading = true);
    });
    _timeoutTimer = Timer(_loadTimeout, () {
      if (mounted) setState(() => _hasError = true);
    });

    try {
      await context.read<DataProvider>().init();
      // Ignore a superseded attempt (e.g. a stale future resolving after the
      // timeout fired and the user hit Retry).
      if (!mounted || _hasError || generation != _loadGeneration) return;
      _cancelTimers();
      Navigator.of(context).pushReplacementNamed(MainScreen.routeName);
    } catch (_) {
      if (generation != _loadGeneration) return;
      _cancelTimers();
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _retry() {
    _cancelTimers();
    setState(() {
      _hasError = false;
      _stillLoading = false;
    });
    _loadData();
  }

  bool get _hasDownloads =>
      context.read<DownloadProvider>().playables.isNotEmpty;

  void _viewDownloads() {
    _cancelTimers();
    AppState.set('mode', AppMode.offline);
    Navigator.of(context).pushReplacementNamed(MainScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientDecoratedContainer(
        child: _hasError
            ? OopsBox(showLogOutButton: true, onRetry: _retry)
            : _buildLoading(),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Spinner(),
          if (_stillLoading) ...[
            const SizedBox(height: 28),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'This is taking longer than usual…',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
            ),
            if (_hasDownloads) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _viewDownloads,
                child: const Text('View Downloads'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

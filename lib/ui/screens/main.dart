import 'dart:io';

import 'package:app/app_state.dart';
import 'package:app/constants/constants.dart';
import 'package:app/enums.dart';
import 'package:app/main.dart';
import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/screens/screens.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  static const routeName = '/main';

  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const tabBarHeight = 60.0;
  int _selectedIndex = 0;
  var _isOffline = AppState.get('mode', AppMode.online) == AppMode.offline;

  static const List<Widget> _widgetOptions = [
    const HomeScreen(),
    const SearchScreen(),
    const LibraryScreen(),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  void initState() {
    super.initState();

    audioHandler.init(
      playableProvider: context.read<PlayableProvider>(),
      downloadProvider: context.read<DownloadProvider>(),
    );
  }

  BottomNavigationBarItem tabBarItem({
    required String title,
    required IconData icon,
  }) {
    return BottomNavigationBarItem(
      icon: Column(
        children: [
          const SizedBox(height: 14.0),
          Icon(icon),
          const SizedBox(height: 4.0),
          Text(title),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        body: _isOffline
            ? Stack(
                children: [
                  DownloadedScreen(inOfflineMode: true),
                  Positioned(
                    bottom: 0,
                    width: MediaQuery.of(context).size.width,
                    child: Container(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const MiniPlayer(),
                          const ConnectivityInfoBox(),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Stack(
                children: <Widget>[
                  CupertinoTabScaffold(
                    tabBuilder: (_, index) {
                      return CupertinoTabView(
                          builder: (_) => _widgetOptions[index]);
                    },
                    tabBar: CupertinoTabBar(
                      backgroundColor: Colors.black12,
                      iconSize: 24,
                      activeColor: Colors.white,
                      height: tabBarHeight,
                      inactiveColor: Colors.white54,
                      border: Border(top: Divider.createBorderSide(context)),
                      items: <BottomNavigationBarItem>[
                        tabBarItem(
                          title: 'Home',
                          icon: CupertinoIcons.house_fill,
                        ),
                        tabBarItem(
                          title: 'Search',
                          icon: CupertinoIcons.search,
                        ),
                        tabBarItem(
                          title: 'Library',
                          icon: CupertinoIcons.music_albums_fill,
                        ),
                      ],
                      currentIndex: _selectedIndex,
                      onTap: _onItemTapped,
                    ),
                  ),
                  Positioned(
                    bottom:
                        tabBarHeight + MediaQuery.of(context).padding.bottom,
                    width: MediaQuery.of(context).size.width,
                    child: const MiniPlayer(),
                  ),
                ],
              ),
      ),
      onWillPop: () async {
        if (!Platform.isAndroid || Navigator.of(context).canPop()) return true;
        MethodChannel('dev.koel.app').invokeMethod('minimize');
        return false;
      },
    );
  }
}

class ConnectivityInfoBox extends StatefulWidget {
  const ConnectivityInfoBox({Key? key}) : super(key: key);

  @override
  _ConnectivityInfoBoxState createState() => _ConnectivityInfoBoxState();
}

class _ConnectivityInfoBoxState extends State<ConnectivityInfoBox>
    with StreamSubscriber {
  var _offline = true;

  @override
  void initState() {
    super.initState();

    subscribe(Connectivity().onConnectivityChanged.listen((event) {
      setState(() => _offline = event == ConnectivityResult.none);
    }));
  }

  @override
  void dispose() {
    unsubscribeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var padding = EdgeInsets.only(top: 16, bottom: Platform.isIOS ? 32 : 16);

    return FrostedGlassBackground(
      child: Container(
        width: double.infinity,
        child: _offline
            ? Container(
                padding: padding,
                child: Wrap(
                    spacing: 8.0,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.wifi_slash,
                        color: Colors.white54,
                        size: 20,
                      ),
                      const Text(
                        'No internet connection',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ]),
              )
            : Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: padding,
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.transparent,
                  ),
                  onPressed: () {
                    AppState.delete('mode');
                    Navigator.of(context).pushReplacementNamed(
                      InitialScreen.routeName,
                    );
                  },
                  icon: const Icon(
                    CupertinoIcons.wifi,
                    color: AppColors.white,
                    size: 20,
                  ),
                  label: const Text(
                    'Connection restored! Tap to refresh.',
                    style: TextStyle(color: AppColors.white, fontSize: 14.0),
                  ),
                ),
              ),
      ),
    );
  }
}

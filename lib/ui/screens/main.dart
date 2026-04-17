import 'dart:io';

import 'package:app/app_state.dart';
import 'package:app/constants/constants.dart';
import 'package:app/enums.dart';
import 'package:app/main.dart';
import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/screens/screens.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:app/utils/route_state.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  static const routeName = '/main';

  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const tabBarHeight = 60.0;
  late int _selectedIndex;
  var _isOffline = AppState.get('mode', AppMode.online) == AppMode.offline;

  final _navigatorKeys = List.generate(
    3,
    (_) => GlobalKey<NavigatorState>(),
  );

  late final List<RouteStateObserver> _routeObservers;

  static const List<Widget> _widgetOptions = [
    const HomeScreen(),
    const SearchScreen(),
    const LibraryScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == _selectedIndex) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() => _selectedIndex = index);
      RouteState.setTabIndex(index);
    }
  }

  @override
  void initState() {
    super.initState();

    RouteState.load();
    _selectedIndex = RouteState.tabIndex;
    _routeObservers = List.generate(
      3,
      (i) => RouteStateObserver(tabIndex: i),
    );

    audioHandler.init(
      playableProvider: context.read<PlayableProvider>(),
      downloadProvider: context.read<DownloadProvider>(),
    );

    context.read<DownloadSyncProvider>().scheduleSync();

    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreRoutes());
  }

  void _restoreRoutes() {
    // Take a snapshot of the persisted stacks, then clear them.
    // The observer's didPush calls will re-populate them as routes are pushed.
    final savedStacks = <int, List<RouteEntry>>{};
    for (var tab = 0; tab < 3; tab++) {
      savedStacks[tab] = List.of(RouteState.stackFor(tab));
    }
    RouteState.clear();
    RouteState.setTabIndex(_selectedIndex);

    for (var tab = 0; tab < 3; tab++) {
      final stack = savedStacks[tab]!;
      final navigator = _navigatorKeys[tab].currentState;
      if (navigator == null || stack.isEmpty) continue;

      for (final entry in stack) {
        final screen = entry.buildScreen();
        if (screen == null) {
          debugPrint('RouteState: unknown route "${entry.name}", skipping');
          continue;
        }

        navigator.push(CupertinoPageRoute(
          settings: RouteSettings(name: entry.name, arguments: entry.argument),
          builder: (_) => screen,
        ));
      }
    }
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
    return Scaffold(
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
                        navigatorKey: _navigatorKeys[index],
                        navigatorObservers: [_routeObservers[index]],
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

import 'dart:ui';

import 'package:app/constants/dimens.dart';
import 'package:app/providers/audio_player_provider.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/ui/screens/home.dart';
import 'package:app/ui/screens/library.dart';
import 'package:app/ui/screens/search.dart';
import 'package:app/ui/widgets/footer_player_sheet.dart';
import 'package:flutter/cupertino.dart'
    show
        CupertinoIcons,
        CupertinoPageScaffold,
        CupertinoTabBar,
        CupertinoTabScaffold,
        CupertinoTabView;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({Key? key}) : super(key: key);

  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  late Future futureData;
  int _selectedIndex = 0;
  late AudioPlayerProvider audio;
  late final _tabBarKey = GlobalKey();

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  void initState() {
    super.initState();

    futureData = context.read<DataProvider>().init(context);
    audio = context.read<AudioPlayerProvider>()..init();
  }

  @override
  Widget build(BuildContext context) {
    Container loadingWidget = Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(child: CircularProgressIndicator()),
        ],
      ),
    );

    return FutureBuilder(
      future: futureData,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return loadingWidget;
          default:
            return Scaffold(
              body: Stack(
                children: [
                  CupertinoTabScaffold(
                    tabBuilder: (context, index) {
                      return CupertinoTabView(builder: (context) {
                        return _widgetOptions[index];
                      });
                    },
                    tabBar: CupertinoTabBar(
                      key: _tabBarKey,
                      backgroundColor: Colors.grey.withOpacity(.1),
                      iconSize: 24,
                      activeColor: Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withOpacity(.2),
                          width: 0.5, // One physical pixel.
                        ),
                      ),
                      items: const <BottomNavigationBarItem>[
                        BottomNavigationBarItem(
                          icon: Icon(CupertinoIcons.house_fill),
                          label: 'Home',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(CupertinoIcons.search),
                          label: 'Search',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(CupertinoIcons.music_albums_fill),
                          label: 'Library',
                        ),
                      ],
                      currentIndex: _selectedIndex,
                      onTap: _onItemTapped,
                    ),
                  ),
                  Positioned(
                    // 50 is the standard iOS (10) tab bar height.
                    bottom: 50 + MediaQuery.of(context).padding.bottom,
                    width: MediaQuery.of(context).size.width,
                    child: FooterPlayerSheet(),
                  ),
                ],
              ),
            );
        }
      },
    );
  }
}

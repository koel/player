import 'package:app/constants/dimens.dart';
import 'package:app/providers/audio_player_provider.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/ui/screens/home.dart';
import 'package:app/ui/screens/library.dart';
import 'package:app/ui/screens/search.dart';
import 'package:app/ui/widgets/footer_player_sheet.dart';
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
            return Container(
              alignment: Alignment.center,
              child: Scaffold(
                body: Container(
                  padding: EdgeInsets.symmetric(horizontal: AppDimens.horizontalPadding),
                  child: _widgetOptions.elementAt(_selectedIndex),
                ),
                bottomSheet: FooterPlayerSheet(),
                bottomNavigationBar: BottomNavigationBar(
                  elevation: 0,
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.search),
                      label: 'Search',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.library_music),
                      label: 'Library',
                    ),
                  ],
                  currentIndex: _selectedIndex,
                  selectedItemColor: Colors.white,
                  onTap: _onItemTapped,
                ),
              ),
            );
        }
      },
    );
  }
}

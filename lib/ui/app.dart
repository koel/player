import 'package:app/constants/strings.dart';
import 'package:app/ui/screens/add_to_playlist.dart';
import 'package:app/ui/screens/album_details.dart';
import 'package:app/ui/screens/albums.dart';
import 'package:app/ui/screens/artist_details.dart';
import 'package:app/ui/screens/artists.dart';
import 'package:app/ui/screens/data_loading.dart';
import 'package:app/ui/screens/favorites.dart';
import 'package:app/ui/screens/home.dart';
import 'package:app/ui/screens/initial.dart';
import 'package:app/ui/screens/library.dart';
import 'package:app/ui/screens/login.dart';
import 'package:app/ui/screens/main.dart';
import 'package:app/ui/screens/playlist_details.dart';
import 'package:app/ui/screens/playlists.dart';
import 'package:app/ui/screens/profile.dart';
import 'package:app/ui/screens/queue.dart';
import 'package:app/ui/screens/search.dart';
import 'package:app/ui/screens/songs.dart';
import 'package:app/ui/theme_data.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    return Material(
      color: Colors.transparent,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppStrings.appName,
        theme: themeData(context),
        initialRoute: InitialScreen.routeName,
        routes: {
          InitialScreen.routeName: (_) => const InitialScreen(),
          LoginScreen.routeName: (_) => const LoginScreen(),
          MainScreen.routeName: (_) => const MainScreen(),
          HomeScreen.routeName: (_) => const HomeScreen(),
          SearchScreen.routeName: (_) => const SearchScreen(),
          LibraryScreen.routeName: (_) => const LibraryScreen(),
          FavoritesScreen.routeName: (_) => const FavoritesScreen(),
          PlaylistsScreen.routeName: (_) => const PlaylistsScreen(),
          SongsScreen.routeName: (_) => const SongsScreen(),
          ArtistsScreen.routeName: (_) => const ArtistsScreen(),
          AlbumsScreen.routeName: (_) => const AlbumsScreen(),
          AlbumDetailsScreen.routeName: (_) => const AlbumDetailsScreen(),
          ArtistDetailsScreen.routeName: (_) => const ArtistDetailsScreen(),
          PlaylistDetailsScreen.routeName: (_) => const PlaylistDetailsScreen(),
          QueueScreen.routeName: (_) => const QueueScreen(),
          AddToPlaylistScreen.routeName: (_) => const AddToPlaylistScreen(),
          ProfileScreen.routeName: (_) => const ProfileScreen(),
          DataLoadingScreen.routeName: (_) => const DataLoadingScreen(),
        },
      ),
    );
  }
}

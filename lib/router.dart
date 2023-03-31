import 'package:app/models/models.dart';
import 'package:app/ui/screens/add_to_playlist.dart';
import 'package:app/ui/screens/album_details.dart';
import 'package:app/ui/screens/albums.dart';
import 'package:app/ui/screens/artist_details.dart';
import 'package:app/ui/screens/artists.dart';
import 'package:app/ui/screens/create_playlist_sheet.dart';
import 'package:app/ui/screens/data_loading.dart';
import 'package:app/ui/screens/downloaded.dart';
import 'package:app/ui/screens/favorites.dart';
import 'package:app/ui/screens/home.dart';
import 'package:app/ui/screens/initial.dart';
import 'package:app/ui/screens/library.dart';
import 'package:app/ui/screens/login.dart';
import 'package:app/ui/screens/no_connection.dart';
import 'package:app/ui/screens/now_playing.dart';
import 'package:app/ui/screens/playlist_details.dart';
import 'package:app/ui/screens/playlists.dart';
import 'package:app/ui/screens/queue.dart';
import 'package:app/ui/screens/main.dart';
import 'package:app/ui/screens/search.dart';
import 'package:app/ui/screens/song_action_sheet.dart';
import 'package:app/ui/screens/songs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppRouter {
  const AppRouter();

  static Map<String, Widget Function(BuildContext)> routes = {
    InitialScreen.routeName: (_) => const InitialScreen(),
    NoConnectionScreen.routeName: (_) => const NoConnectionScreen(),
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
    DataLoadingScreen.routeName: (_) => const DataLoadingScreen(),
    DownloadedScreen.routeName: (_) => DownloadedScreen(),
  };

  Future<void> gotoAlbumDetailsScreen(
    BuildContext context, {
    required int albumId,
  }) async {
    await Navigator.of(context).push(CupertinoPageRoute(
      builder: (_) => const AlbumDetailsScreen(),
      settings: RouteSettings(arguments: albumId),
    ));
  }

  Future<void> gotoArtistDetailsScreen(
    BuildContext context, {
    required int artistId,
  }) async {
    await Navigator.of(context).push(CupertinoPageRoute(
      builder: (_) => const ArtistDetailsScreen(),
      settings: RouteSettings(arguments: artistId),
    ));
  }

  Future<void> openNowPlayingScreen(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height,
          child: const NowPlayingScreen(),
        );
      },
    );
  }

  Future<void> showCreatePlaylistSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height,
          child: const CreatePlaylistSheet(),
        );
      },
    );
  }

  Future<void> showActionSheet(
    BuildContext context, {
    required Song song,
  }) async {
    showModalBottomSheet<void>(
      useRootNavigator: true, // covering everything else
      context: context,
      isScrollControlled: true,
      builder: (_) => SongActionSheet(song: song),
    );
  }
}

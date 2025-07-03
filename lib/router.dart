import 'package:app/models/models.dart';
import 'package:app/ui/screens/screens.dart';
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
    RecentlyPlayedScreen.routeName: (_) => const RecentlyPlayedScreen(),
  };

  Future<void> gotoAlbumDetailsScreen(
    BuildContext context, {
    required dynamic albumId,
  }) async {
    await Navigator.of(context).push(CupertinoPageRoute(
      builder: (_) => const AlbumDetailsScreen(),
      settings: RouteSettings(arguments: albumId),
    ));
  }

  Future<void> gotoArtistDetailsScreen(
    BuildContext context, {
    required dynamic artistId,
  }) async {
    await Navigator.of(context).push(CupertinoPageRoute(
      builder: (_) => const ArtistDetailsScreen(),
      settings: RouteSettings(arguments: artistId),
    ));
  }

  gotoPodcastDetailsScreen(
    BuildContext context, {
    required String podcastId,
  }) async {
    await Navigator.of(context).push(CupertinoPageRoute(
      builder: (_) => const PodcastDetailsScreen(),
      settings: RouteSettings(arguments: podcastId),
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

  Future<void> showPlayableActionSheet(
    BuildContext context, {
    required Playable playable,
  }) async {
    showModalBottomSheet<void>(
      useRootNavigator: true, // covering everything else
      context: context,
      isScrollControlled: true,
      builder: (_) => PlayableActionSheet(playable: playable),
    );
  }

  Future<void> showAddPodcastSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height,
          child: const AddPodcastSheet(),
        );
      },
    );
  }
}

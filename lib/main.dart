import 'package:app/providers/providers.dart';
import 'package:app/ui/app.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> _providers = [
  Provider(create: (_) => AppStateProvider()),
  Provider(create: (_) => AuthProvider()),
  ChangeNotifierProvider(create: (_) => ArtistProvider()),
  Provider(create: (_) => MediaInfoProvider()),
  ChangeNotifierProvider(create: (_) => DownloadProvider()),
  ChangeNotifierProvider(
    create: (context) => AlbumProvider(),
  ),
  ChangeNotifierProvider(
    create: (context) => SongProvider(
      downloadProvider: context.read<DownloadProvider>(),
      appState: context.read<AppStateProvider>(),
    ),
  ),
  ChangeNotifierProvider(
    create: (context) => FavoriteProvider(
      songProvider: context.read<SongProvider>(),
      appState: context.read<AppStateProvider>(),
    ),
  ),
  ChangeNotifierProvider(
    create: (context) => RecentlyPlayedProvider(
      songProvider: context.read<SongProvider>(),
    ),
  ),
  ChangeNotifierProvider(
    create: (context) => InteractionProvider(
      songProvider: context.read<SongProvider>(),
    ),
  ),
  ChangeNotifierProvider(
    create: (context) => PlaylistProvider(
      songProvider: context.read<SongProvider>(),
      appState: context.read<AppStateProvider>(),
    ),
  ),
  ChangeNotifierProvider(
    create: (context) => AudioProvider(
      songProvider: context.read<SongProvider>(),
      interactionProvider: context.read<InteractionProvider>(),
      downloadProvider: context.read<DownloadProvider>(),
    ),
  ),
  ChangeNotifierProvider(
    create: (context) => SearchProvider(
      songProvider: context.read<SongProvider>(),
      artistProvider: context.read<ArtistProvider>(),
      albumProvider: context.read<AlbumProvider>(),
    ),
  ),
  ChangeNotifierProvider(
    create: (context) => DataProvider(
      playlistProvider: context.read<PlaylistProvider>(),
    ),
  ),
  ChangeNotifierProvider(
    create: (context) => OverviewProvider(
      songProvider: context.read<SongProvider>(),
      albumProvider: context.read<AlbumProvider>(),
      artistProvider: context.read<ArtistProvider>(),
      recentlyPlayedProvider: context.read<RecentlyPlayedProvider>(),
    ),
  ),
];

Future<void> main() async {
  AssetsAudioPlayer.setupNotificationsOpenAction((notification) {
    return true;
  });

  await GetStorage.init('Preferences');
  await GetStorage.init(DownloadProvider.serializedSongContainer);

  runApp(
    MultiProvider(
      providers: _providers,
      child: App(),
    ),
  );
}

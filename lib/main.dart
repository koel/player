import 'dart:async';

import 'package:app/audio_handler.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/app.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

late KoelAudioHandler audioHandler;

List<SingleChildWidget> _providers = [
  Provider(create: (_) => AuthProvider()),
  ChangeNotifierProvider(create: (_) => ArtistProvider()),
  ChangeNotifierProvider(create: (context) => SongProvider()),
  Provider(create: (_) => MediaInfoProvider()),
  // Download files should always be available to adapt to login/logout and
  // offline mode.
  Provider(
      create: (context) => DownloadProvider(
            songProvider: context.read<SongProvider>(),
          ),
      lazy: false),
  ChangeNotifierProvider(create: (context) => AlbumProvider()),
  ChangeNotifierProvider(
    create: (context) => FavoriteProvider(
      songProvider: context.read<SongProvider>(),
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
      recentlyPlayedProvider: context.read<RecentlyPlayedProvider>(),
    ),
    // By setting lazy to false, we ensure that the provider is initialized
    // before the app is launched. This makes sure that the provider listens
    // to the audio handler's state changes.
    lazy: false,
  ),
  ChangeNotifierProvider(
    create: (context) => PlaylistProvider(),
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
    ),
  ),
  ChangeNotifierProvider(
    create: (context) => SongListScreenProvider(
      songProvider: context.read<SongProvider>(),
      searchProvider: context.read<SearchProvider>(),
    ),
  ),
];

Future<void> main() async {
  audioHandler = await AudioService.init(
    builder: () => KoelAudioHandler(),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'dev.koel.app.channel.audio',
      androidNotificationChannelName: 'Koel audio playback',
      androidNotificationOngoing: true,
    ),
  );

  await GetStorage.init('Preferences');
  await GetStorage.init(DownloadProvider.serializedSongContainer);

  runApp(
    MultiProvider(
      providers: _providers,
      child: const App(),
    ),
  );
}

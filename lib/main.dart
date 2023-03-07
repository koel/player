import 'package:app/providers/album_provider.dart';
import 'package:app/providers/artist_provider.dart';
import 'package:app/providers/audio_provider.dart';
import 'package:app/providers/auth_provider.dart';
import 'package:app/providers/cache_provider.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/providers/interaction_provider.dart';
import 'package:app/providers/media_info_provider.dart';
import 'package:app/providers/overview_provider.dart';
import 'package:app/providers/playlist_provider.dart';
import 'package:app/providers/recently_played_provider.dart';
import 'package:app/providers/search_provider.dart';
import 'package:app/providers/song_provider.dart';
import 'package:app/ui/app.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> _providers = [
  Provider(create: (_) => AuthProvider()),
  ChangeNotifierProvider(create: (_) => ArtistProvider()),
  Provider(create: (_) => MediaInfoProvider()),
  ChangeNotifierProvider(create: (_) => CacheProvider()),
  ChangeNotifierProvider(
    create: (context) => AlbumProvider(
      artistProvider: context.read<ArtistProvider>(),
    ),
  ),
  ChangeNotifierProvider(
    create: (context) => SongProvider(
      artistProvider: context.read<ArtistProvider>(),
      albumProvider: context.read<AlbumProvider>(),
      cacheProvider: context.read<CacheProvider>(),
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
    ),
  ),
  ChangeNotifierProvider(
    create: (context) => AudioProvider(
      songProvider: context.read<SongProvider>(),
      interactionProvider: context.read<InteractionProvider>(),
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
  await GetStorage.init('Cache');
  GetStorage('Cache').erase();

  runApp(
    MultiProvider(
      providers: _providers,
      child: App(),
    ),
  );
}

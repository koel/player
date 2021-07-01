import 'package:app/providers/album_provider.dart';
import 'package:app/providers/artist_provider.dart';
import 'package:app/providers/audio_player_provider.dart';
import 'package:app/providers/auth_provider.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/providers/search_provider.dart';
import 'package:app/providers/song_provider.dart';
import 'package:app/providers/user_provider.dart';
import 'package:app/ui/koel_app.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  AssetsAudioPlayer.setupNotificationsOpenAction((notification) {
    print(notification.audioId);
    return true;
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ArtistProvider()),
        ChangeNotifierProvider(
          create: (context) => AlbumProvider(
            artistProvider: context.read<ArtistProvider>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => SongProvider(
            artistProvider: context.read<ArtistProvider>(),
            albumProvider: context.read<AlbumProvider>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => AudioPlayerProvider(
            songProvider: context.read<SongProvider>(),
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
            songProvider: context.read<SongProvider>(),
            artistProvider: context.read<ArtistProvider>(),
            albumProvider: context.read<AlbumProvider>(),
          ),
        ),
      ],
      child: KoelApp(),
    ),
  );
}

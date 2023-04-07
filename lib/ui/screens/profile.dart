import 'dart:ui';

import 'package:app/constants/dimensions.dart';
import 'package:app/models/user.dart';
import 'package:app/providers/audio_provider.dart';
import 'package:app/providers/auth_provider.dart';
import 'package:app/providers/cache_provider.dart';
import 'package:app/providers/interaction_provider.dart';
import 'package:app/providers/playlist_provider.dart';
import 'package:app/providers/song_provider.dart';
import 'package:app/ui/screens/favorites.dart';
import 'package:app/ui/screens/login.dart';
import 'package:app/ui/screens/playlists.dart';
import 'package:app/ui/screens/songs.dart';
import 'package:app/ui/widgets/app_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide AppBar;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  static const routeName = '/profile';

  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    AuthProvider authProvider = context.watch();
    SongProvider songProvider = context.watch();
    PlaylistProvider playlistProvider = context.watch();

    User user = authProvider.authUser;

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          AppBar(
            headingText: user.name,
            coverImage: SizedBox(
              width: 192,
              height: 192,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: user.avatar,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(96)),
                  boxShadow: <BoxShadow>[
                    const BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.0,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),
            ),
            backgroundImage: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: user.avatar,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.horizontalPadding,
                vertical: 16,
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        child: MetricBlock(
                          number: songProvider.songs.length,
                          label: 'songs',
                        ),
                        onTap: () => Navigator.of(context, rootNavigator: true)
                            .pushNamed(SongsScreen.routeName),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        child: MetricBlock(
                          number: playlistProvider.playlists.length,
                          label: 'playlists',
                        ),
                        onTap: () => Navigator.of(context, rootNavigator: true)
                            .pushNamed(PlaylistsScreen.routeName),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        child: const FavoriteMetricBlock(),
                        onTap: () => Navigator.of(context, rootNavigator: true)
                            .pushNamed(FavoritesScreen.routeName),
                      ),
                    ],
                  ),
                  SizedBox(height: 32),
                  Row(
                    children: <Widget>[
                      const LogOutButton(),
                      const SizedBox(width: 12),
                      const ClearCacheButton(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LogOutButton extends StatelessWidget {
  const LogOutButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    AuthProvider auth = context.watch();
    AudioProvider audio = context.watch();

    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          primary: Colors.red,
        ),
        onPressed: () {
          showCupertinoDialog(
            context: context,
            builder: (BuildContext context) {
              return CupertinoAlertDialog(
                title: const Text('Log out?'),
                actions: <Widget>[
                  CupertinoDialogAction(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoDialogAction(
                    child: const Text('Confirm'),
                    isDestructiveAction: true,
                    onPressed: () async {
                      await auth.logout();
                      await audio.cleanUpUponLogout();
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushNamedAndRemoveUntil(
                        LoginScreen.routeName,
                        (_) => false,
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
        child: const Text('Log Out', textAlign: TextAlign.center),
      ),
    );
  }
}

class ClearCacheButton extends StatelessWidget {
  const ClearCacheButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    CacheProvider cache = context.watch();

    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(),
        onPressed: () async {
          showCupertinoDialog(
            context: context,
            builder: (BuildContext context) {
              return CupertinoAlertDialog(
                title: const Text('Clear all media cache?'),
                content: const Text('You cannot undo this action.'),
                actions: <Widget>[
                  CupertinoDialogAction(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoDialogAction(
                    child: const Text('Confirm'),
                    isDestructiveAction: true,
                    onPressed: () async {
                      await cache.clear();
                      Navigator.pop(context);
                      showCupertinoDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return CupertinoAlertDialog(
                            content: const Text('Media cache cleared.'),
                            actions: <Widget>[
                              CupertinoDialogAction(
                                child: const Text('OK'),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              );
            },
          );
          await DefaultCacheManager().emptyCache();
        },
        child: const Text('Clear Cache', textAlign: TextAlign.center),
      ),
    );
  }
}

class FavoriteMetricBlock extends StatelessWidget {
  const FavoriteMetricBlock({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<InteractionProvider>(
      builder: (_, provider, __) {
        return MetricBlock(
          number: provider.favorites.length,
          label: 'favorites',
        );
      },
    );
  }
}

class MetricBlock extends StatelessWidget {
  final int number;
  final String label;

  const MetricBlock({Key? key, required this.number, required this.label})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    NumberFormat numberFormat = NumberFormat.decimalPattern('en_US');

    return Column(
      children: <Widget>[
        Text(
          numberFormat.format(number),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        Text(
          label.toUpperCase(),
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }
}

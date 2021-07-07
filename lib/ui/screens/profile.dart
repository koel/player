import 'dart:ui';

import 'package:app/constants/dimens.dart';
import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/user.dart';
import 'package:app/providers/auth_provider.dart';
import 'package:app/providers/cache_provider.dart';
import 'package:app/providers/interaction_provider.dart';
import 'package:app/providers/playlist_provider.dart';
import 'package:app/providers/song_provider.dart';
import 'package:app/ui/screens/favorites.dart';
import 'package:app/ui/screens/library.dart';
import 'package:app/ui/screens/login.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
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
          SliverAppBar(
            pinned: true,
            expandedHeight: 290,
            flexibleSpace: FlexibleSpaceBar(
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(user.name, overflow: TextOverflow.ellipsis),
              ),
              background: Stack(
                children: <Widget>[
                  SizedBox(
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
                  const SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: const DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Colors.transparent,
                            Colors.black,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: SizedBox(
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
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.horizontalPadding,
                vertical: 16,
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      GestureDetector(
                        child: MetricBlock(
                          number: songProvider.songs.length,
                          label: 'songs',
                        ),
                        onTap: () => gotoSongsScreen(context),
                      ),
                      GestureDetector(
                        child: MetricBlock(
                          number: playlistProvider.playlists.length,
                          label: 'playlists',
                        ),
                        onTap: () => gotoPlaylistsScreen(context),
                      ),
                      GestureDetector(
                        child: const FavoriteMetricBlock(),
                        onTap: () => gotoFavoritesScreen(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 32),
                  Row(
                    children: <Widget>[
                      LogOutButton(),
                      const SizedBox(width: 12),
                      ClearCacheButton(),
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

    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.red),
            borderRadius: BorderRadius.circular(6.0),
          ),
          onPrimary: Colors.red,
          primary: Colors.transparent,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        onPressed: () {
          showCupertinoDialog(
            context: context,
            builder: (BuildContext context) {
              return CupertinoAlertDialog(
                title: Text('Log out?'),
                actions: <Widget>[
                  CupertinoDialogAction(
                    child: Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  CupertinoDialogAction(
                    child: Text('Confirm'),
                    isDestructiveAction: true,
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await auth.logout();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (Route route) => false,
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
        child: Text('Log Out', textAlign: TextAlign.center),
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
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.white60),
            borderRadius: BorderRadius.circular(6.0),
          ),
          onPrimary: Colors.white60,
          primary: Colors.transparent,
          textStyle: const TextStyle(
            fontSize: 16,
          ),
        ),
        onPressed: () async {
          showCupertinoDialog(
            context: context,
            builder: (BuildContext context) {
              return CupertinoAlertDialog(
                title: Text('Clear all media cache?'),
                content: Text('You cannot undo this action.'),
                actions: <Widget>[
                  CupertinoDialogAction(
                    child: Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  CupertinoDialogAction(
                    child: Text('Confirm'),
                    isDestructiveAction: true,
                    onPressed: () async {
                      await cache.clear();
                      Navigator.of(context).pop();
                      showCupertinoDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return CupertinoAlertDialog(
                            content: Text('Media cache cleared.'),
                            actions: <Widget>[
                              CupertinoDialogAction(
                                child: Text('OK'),
                                onPressed: () => Navigator.of(context).pop(),
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
        child: Text(
          'Clear Cache',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class FavoriteMetricBlock extends StatefulWidget {
  const FavoriteMetricBlock({Key? key}) : super(key: key);

  @override
  _FavoriteMetricBlock createState() => _FavoriteMetricBlock();
}

class _FavoriteMetricBlock extends State<FavoriteMetricBlock>
    with StreamSubscriber {
  late InteractionProvider interactionProvider;
  late int _favoriteCount;

  @override
  void initState() {
    super.initState();
    interactionProvider = context.read();

    setState(() => _favoriteCount = interactionProvider.favorites.length);

    subscribe(interactionProvider.songLikeToggledStream.listen((song) {
      setState(() => _favoriteCount = interactionProvider.favorites.length);
    }));
  }

  @override
  Widget build(BuildContext context) {
    return MetricBlock(
      number: _favoriteCount,
      label: 'favorites',
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

gotoProfileScreen(BuildContext context) {
  Navigator.of(context).push(
    CupertinoPageRoute<void>(
      builder: (_) => const ProfileScreen(),
      title: 'Profile',
    ),
  );
}

import 'dart:ui';

import 'package:app/constants/dimens.dart';
import 'package:app/models/user.dart';
import 'package:app/providers/interaction_provider.dart';
import 'package:app/providers/playlist_provider.dart';
import 'package:app/providers/song_provider.dart';
import 'package:app/providers/user_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    UserProvider userProvider = context.watch();
    SongProvider songProvider = context.watch();
    InteractionProvider interactionProvider = context.watch();
    PlaylistProvider playlistProvider = context.watch();

    User user = userProvider.authUser;

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
                      MetricBlock(
                        number: songProvider.songs.length,
                        label: 'songs',
                      ),
                      MetricBlock(
                        number: playlistProvider.playlists.length,
                        label: 'playlists',
                      ),
                      MetricBlock(
                        number: interactionProvider.favorites.length,
                        label: 'favorites',
                      ),
                    ],
                  ),
                  SizedBox(height: 32),
                  Row(
                    children: <Widget>[
                      Expanded(
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
                          onPressed: () {},
                          child: Text('Log Out', textAlign: TextAlign.center),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
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
                          onPressed: () {},
                          child: Text(
                            'Clear Cache',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
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

import 'dart:async';

import 'package:app/models/song.dart';
import 'package:app/providers/interaction_provider.dart';
import 'package:app/ui/widgets/song_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FavoritesScreen extends StatefulWidget {
  final String? previousPageTitle;

  const FavoritesScreen({
    Key? key,
    this.previousPageTitle,
  }) : super(key: key);

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late final InteractionProvider interactionProvider;
  final List<StreamSubscription> _subscriptions = [];
  late List<Song> _songs = [];

  @override
  void initState() {
    super.initState();
    interactionProvider = context.read();

    setState(() => _songs = interactionProvider.favorites);

    _subscriptions.add(interactionProvider.songLikedStream.listen((song) {
      // add song to list
      _songs.add(song);
    }));

    _subscriptions.add(interactionProvider.songUnlikedStream.listen((song) {
      // remove song from list
      _songs.remove(song);
    }));
  }

  @override
  void dispose() {
    _subscriptions.forEach((subscription) => subscription.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            backgroundColor: Colors.black,
            previousPageTitle: widget.previousPageTitle,
            largeTitle: Text(
              'Favorites',
              style: TextStyle(color: Colors.white),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, int index) => SongRow(song: _songs[index]),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/interaction_provider.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/song_list.dart';
import 'package:app/ui/widgets/song_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FavoritesScreen extends StatefulWidget {
  final String? previousPageTitle;

  const FavoritesScreen({Key? key, this.previousPageTitle}) : super(key: key);

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with StreamSubscriber {
  late final InteractionProvider interactionProvider;
  late List<Song> _songs = [];

  @override
  void initState() {
    super.initState();
    interactionProvider = context.read();

    setState(() => _songs = interactionProvider.favorites);

    subscribe(interactionProvider.songLikeToggledStream.listen((song) {
      song.liked ? _songs.add(song) : _songs.remove(song);
    }));
  }

  @override
  void dispose() {
    unsubscribeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: <Widget>[
          CupertinoSliverNavigationBar(
            backgroundColor: Colors.black,
            previousPageTitle: widget.previousPageTitle,
            largeTitle: const Text(
              'Favorites',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          SliverToBoxAdapter(child: SongListButtons(songs: _songs)),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, int index) {
                return Dismissible(
                  direction: DismissDirection.endToStart,
                  onDismissed: (DismissDirection direction) =>
                      interactionProvider.unlike(song: _songs[index]),
                  background: Container(
                    alignment: AlignmentDirectional.centerEnd,
                    color: Colors.red,
                    child: const Padding(
                      padding: const EdgeInsets.only(right: 28),
                      child: const Icon(CupertinoIcons.heart_slash),
                    ),
                  ),
                  key: ValueKey(_songs[index]),
                  child: SongRow(song: _songs[index]),
                );
              },
              childCount: _songs.length,
            ),
          ),
          SliverToBoxAdapter(child: bottomSpace()),
        ],
      ),
    );
  }
}

void gotoFavoritesScreen(BuildContext context, {String? previousPageTitle}) {
  Navigator.of(context).push(
    CupertinoPageRoute(
      builder: (_) => FavoritesScreen(
        previousPageTitle: previousPageTitle,
      ),
    ),
  );
}

import 'package:app/providers/interaction_provider.dart';
import 'package:app/ui/widgets/app_bar.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/song_list_buttons.dart';
import 'package:app/ui/widgets/song_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide AppBar;
import 'package:provider/provider.dart';

class FavoritesScreen extends StatelessWidget {
  static const routeName = '/favorites';

  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<InteractionProvider>(
        builder: (_, provider, __) {
          return CustomScrollView(
            slivers: <Widget>[
              AppBar(
                headingText: 'Favorites',
                coverImage: CoverImageStack(songs: provider.favorites),
              ),
              SliverToBoxAdapter(
                child: SongListButtons(songs: provider.favorites),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, int index) {
                    return Dismissible(
                      direction: DismissDirection.endToStart,
                      onDismissed: (DismissDirection direction) =>
                          provider.unlike(song: provider.favorites[index]),
                      background: Container(
                        alignment: AlignmentDirectional.centerEnd,
                        color: Colors.red,
                        child: const Padding(
                          padding: EdgeInsets.only(right: 28),
                          child: Icon(CupertinoIcons.heart_slash),
                        ),
                      ),
                      key: ValueKey(provider.favorites[index]),
                      child: SongRow(song: provider.favorites[index]),
                    );
                  },
                  childCount: provider.favorites.length,
                ),
              ),
              const SliverToBoxAdapter(child: const BottomSpace()),
            ],
          );
        },
      ),
    );
  }
}

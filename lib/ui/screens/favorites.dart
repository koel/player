import 'package:app/constants/constants.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/widgets/app_bar.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/song_list_buttons.dart';
import 'package:app/ui/widgets/song_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide AppBar;
import 'package:provider/provider.dart';

class FavoritesScreen extends StatefulWidget {
  static const routeName = '/favorites';

  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();

    var favoriteProvider = context.read<FavoriteProvider>();
    if (favoriteProvider.songs.isEmpty) {
      favoriteProvider.fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<FavoriteProvider>(
        builder: (_, provider, __) {
          if (provider.songs.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.horizontalPadding,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(
                      CupertinoIcons.heart,
                      size: 56.0,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'No favorites',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16.0),
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(color: Colors.white54),
                        children: <InlineSpan>[
                          TextSpan(text: 'Tap the'),
                          WidgetSpan(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5.0),
                              child: Icon(
                                CupertinoIcons.heart_solid,
                                size: 16.0,
                              ),
                            ),
                          ),
                          TextSpan(
                            text: 'icon in a song’s menu to mark it as '
                                'favorite.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return CustomScrollView(
            slivers: <Widget>[
              AppBar(
                headingText: 'Favorites',
                coverImage: CoverImageStack(songs: provider.songs),
              ),
              SliverToBoxAdapter(
                child: SongListButtons(songs: provider.songs),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, int index) {
                    return Dismissible(
                      direction: DismissDirection.endToStart,
                      onDismissed: (DismissDirection direction) =>
                          provider.unlike(song: provider.songs[index]),
                      background: Container(
                        alignment: AlignmentDirectional.centerEnd,
                        color: Colors.red,
                        child: const Padding(
                          padding: EdgeInsets.only(right: 28),
                          child: Icon(CupertinoIcons.heart_slash),
                        ),
                      ),
                      key: ValueKey(provider.songs[index]),
                      child: SongRow(song: provider.songs[index]),
                    );
                  },
                  childCount: provider.songs.length,
                ),
              ),
              const BottomSpace(),
            ],
          );
        },
      ),
    );
  }
}

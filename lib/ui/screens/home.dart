import 'package:app/constants/dimensions.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/overview_provider.dart';
import 'package:app/ui/screens/albums.dart';
import 'package:app/ui/screens/artists.dart';
import 'package:app/ui/screens/profile.dart';
import 'package:app/ui/screens/songs.dart';
import 'package:app/ui/widgets/album_card.dart';
import 'package:app/ui/widgets/artist_card.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/horizontal_card_scroller.dart';
import 'package:app/ui/widgets/simple_song_list.dart';
import 'package:app/ui/widgets/song_card.dart';
import 'package:app/ui/widgets/typography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  static const routeName = '/home';

  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<OverviewProvider>(
      builder: (_, overviewProvider, __) {
        overviewProvider.fetchOverview();

        List<Widget> homeBlocks = <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.horizontalPadding,
            ),
            child: SimpleSongList(songs: overviewProvider.recentlyPlayedSongs),
          ),
          HorizontalCardScroller(
            headingText: 'Most played songs',
            cards: <Widget>[
              ...overviewProvider.mostPlayedSongs
                  .map((song) => SongCard(song: song)),
              PlaceholderCard(
                icon: CupertinoIcons.music_note,
                onPressed: () => Navigator.of(context)
                    .push(CupertinoPageRoute(builder: (_) => SongsScreen())),
              ),
            ],
          ),
          HorizontalCardScroller(
            headingText: 'Top albums',
            cards: <Widget>[
              ...overviewProvider.mostPlayedAlbums
                  .map((album) => AlbumCard(album: album)),
              PlaceholderCard(
                icon: CupertinoIcons.music_albums,
                onPressed: () => Navigator.of(context)
                    .push(CupertinoPageRoute(builder: (_) => AlbumsScreen())),
              ),
            ],
          ),
          HorizontalCardScroller(
            headingText: 'Top artists',
            cards: <Widget>[
              ...overviewProvider.mostPlayedArtists
                  .map((artist) => ArtistCard(artist: artist)),
              PlaceholderCard(
                icon: CupertinoIcons.music_mic,
                onPressed: () => Navigator.of(context)
                    .push(CupertinoPageRoute(builder: (_) => ArtistsScreen())),
              ),
            ],
          ),
        ]
            .map(
              (widget) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: widget,
              ),
            )
            .toList();

        return Scaffold(
          body: CupertinoTheme(
            data: CupertinoThemeData(
              primaryColor: Colors.white,
            ),
            child: CustomScrollView(
              slivers: <Widget>[
                CupertinoSliverNavigationBar(
                  backgroundColor: Colors.black,
                  largeTitle: const LargeTitle(text: 'Home'),
                  trailing: IconButton(
                    onPressed: () => Navigator.of(context).push(
                      new CupertinoPageRoute(
                        builder: (_) => const ProfileScreen(),
                      ),
                    ),
                    icon: const Icon(
                      CupertinoIcons.person_alt_circle,
                      size: 24,
                    ),
                  ),
                ),
                SliverList(delegate: SliverChildListDelegate.fixed(homeBlocks)),
                const BottomSpace(height: 128),
              ],
            ),
          ),
        );
      },
    );
  }
}

class MostPlayedSongs extends StatelessWidget {
  final List<Song> songs;
  final BuildContext context;

  const MostPlayedSongs({
    Key? key,
    required this.songs,
    required this.context,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: AppDimensions.horizontalPadding),
          child: const Heading5(text: 'Most played'),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ...songs.expand(
                (song) => [
                  const SizedBox(width: AppDimensions.horizontalPadding),
                  SongCard(song: song),
                ],
              ),
              const SizedBox(width: AppDimensions.horizontalPadding),
              PlaceholderCard(
                icon: CupertinoIcons.music_note,
                onPressed: () => Navigator.of(context, rootNavigator: true)
                    .pushNamed(SongsScreen.routeName),
              ),
              const SizedBox(width: AppDimensions.horizontalPadding),
            ],
          ),
        ),
      ],
    );
  }
}

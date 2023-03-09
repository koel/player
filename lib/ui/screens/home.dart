import 'package:app/constants/constants.dart';
import 'package:app/providers/providers.dart';
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

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OverviewProvider>().fetchOverview();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OverviewProvider>(
      builder: (_, overviewProvider, __) {
        var homeBlocks = <Widget>[
          if (overviewProvider.recentlyPlayedSongs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.horizontalPadding,
              ),
              child: SimpleSongList(
                songs: overviewProvider.recentlyPlayedSongs.getRange(0, 4),
              ),
            ),
          if (overviewProvider.mostPlayedSongs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.horizontalPadding,
              ),
              child: SimpleSongList(
                headingText: 'Most played',
                songs: overviewProvider.mostPlayedSongs,
              ),
            ),
          if (overviewProvider.mostPlayedSongs.isNotEmpty)
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
          if (overviewProvider.mostPlayedAlbums.isNotEmpty)
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
          if (overviewProvider.mostPlayedArtists.isNotEmpty)
            HorizontalCardScroller(
              headingText: 'Top artists',
              cards: <Widget>[
                ...overviewProvider.mostPlayedArtists
                    .map((artist) => ArtistCard(artist: artist)),
                PlaceholderCard(
                  icon: CupertinoIcons.music_mic,
                  onPressed: () => Navigator.of(context).push(
                    CupertinoPageRoute(builder: (_) => const ArtistsScreen()),
                  ),
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
                const BottomSpace(height: 192),
              ],
            ),
          ),
        );
      },
    );
  }
}

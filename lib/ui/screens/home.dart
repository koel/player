import 'package:app/constants/constants.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/placeholders/home_screen_placeholder.dart';
import 'package:app/ui/screens/albums.dart';
import 'package:app/ui/screens/artists.dart';
import 'package:app/ui/screens/recently_played.dart';
import 'package:app/ui/screens/songs.dart';
import 'package:app/ui/widgets/album_card.dart';
import 'package:app/ui/widgets/artist_card.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/horizontal_card_scroller.dart';
import 'package:app/ui/widgets/oops_box.dart';
import 'package:app/ui/widgets/profile_avatar.dart';
import 'package:app/ui/widgets/pull_to_refresh.dart';
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
  var _loading = false;
  var _errored = false;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    if (_loading) return;

    setState(() {
      _errored = false;
      _loading = true;
    });

    try {
      await context.read<OverviewProvider>().refresh();
    } catch (_) {
      setState(() => _errored = true);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OverviewProvider>(
      builder: (_, overviewProvider, __) {
        if (_loading) return const HomeScreenPlaceholder();
        if (_errored) return OopsBox(onRetry: fetchData);

        final blocks = <Widget>[
          if (overviewProvider.mostPlayedSongs.isNotEmpty)
            SimpleSongList(
              headingText: 'Most played',
              songs: overviewProvider.mostPlayedSongs,
            ),
          if (overviewProvider.mostPlayedSongs.isNotEmpty)
            HorizontalCardScroller(
              headingText: 'Most played songs',
              cards: <Widget>[
                ...overviewProvider.mostPlayedSongs
                    .map((song) => SongCard(song: song)),
                PlaceholderCard(
                  icon: CupertinoIcons.music_note,
                  onPressed: () => Navigator.of(context).push(
                    CupertinoPageRoute(builder: (_) => SongsScreen()),
                  ),
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
                  onPressed: () => Navigator.of(context).push(
                    CupertinoPageRoute(builder: (_) => AlbumsScreen()),
                  ),
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
            data: const CupertinoThemeData(
              primaryColor: AppColors.white,
              barBackgroundColor: AppColors.screenHeaderBackground,
            ),
            child: PullToRefresh(
              onRefresh: () => context.read<OverviewProvider>().refresh(),
              child: CustomScrollView(
                slivers: <Widget>[
                  CupertinoSliverNavigationBar(
                    largeTitle: const LargeTitle(text: 'Home'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.of(
                              context,
                              rootNavigator: true,
                            ).pushNamed(RecentlyPlayedScreen.routeName);
                          },
                          icon: const Icon(CupertinoIcons.time, size: 23),
                        ),
                        const ProfileAvatar(),
                      ],
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate.fixed([
                      HomeRecentlyPlayedSection(
                        initialSongs: overviewProvider.recentlyPlayedSongs,
                      ),
                      ...blocks,
                    ]),
                  ),
                  const BottomSpace(height: 192),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class HomeRecentlyPlayedSection extends StatefulWidget {
  final List<Song> initialSongs;

  const HomeRecentlyPlayedSection({Key? key, required this.initialSongs})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _HomeRecentlyPlayedSectionState();
}

class _HomeRecentlyPlayedSectionState extends State<HomeRecentlyPlayedSection> {
  @override
  Widget build(BuildContext context) {
    return Consumer<RecentlyPlayedProvider>(
      builder: (_, overviewProvider, __) {
        final songs = overviewProvider.songs.isNotEmpty
            ? overviewProvider.songs.getRange(0, 4)
            : widget.initialSongs.getRange(0, 4);

        return songs.isEmpty ? SizedBox.shrink() : SimpleSongList(songs: songs);
      },
    );
  }
}

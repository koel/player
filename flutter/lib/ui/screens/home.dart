import 'dart:math';

import 'package:app/constants/constants.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/placeholders/placeholders.dart';
import 'package:app/ui/screens/screens.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HomeScreenState();
}

class _HomeBlock {
  final String id;
  final Widget widget;

  const _HomeBlock(this.id, this.widget);
}

/// Reorders [blocks] to honour the user's saved [savedOrder] (a list of block
/// ids). Blocks named in [savedOrder] come first in that order; the rest keep
/// their default relative order. Ids in [savedOrder] with no matching block are
/// ignored. Returns [blocks] unchanged when no preference is saved.
List<T> orderByHomeBlocksPreference<T>(
  List<T> blocks,
  String Function(T) idOf,
  List<String> savedOrder,
) {
  if (savedOrder.isEmpty) return blocks;

  final indexed = blocks.asMap().entries.toList();

  int sortKey(MapEntry<int, T> entry) {
    final saved = savedOrder.indexOf(idOf(entry.value));
    return saved == -1 ? savedOrder.length + entry.key : saved;
  }

  indexed.sort((left, right) => sortKey(left).compareTo(sortKey(right)));

  return indexed.map((entry) => entry.value).toList();
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

  Widget _songBlock(String heading, List<Playable> songs) {
    return HorizontalCardScroller(
      headingText: heading,
      cards: <Widget>[
        ...songs.map((playable) => SongCard(playable: playable)),
        PlaceholderCard(
          icon: CupertinoIcons.music_note,
          onPressed: () => Navigator.of(context).push(
            CupertinoPageRoute(builder: (_) => SongsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _albumBlock(String heading, List<Album> albums, Set seenAlbumIds) {
    return HorizontalCardScroller(
      headingText: heading,
      cards: <Widget>[
        ...albums.map((album) =>
            AlbumCard(album: album, asHero: seenAlbumIds.add(album.id))),
        PlaceholderCard(
          icon: CupertinoIcons.music_albums,
          onPressed: () => Navigator.of(context).push(
            CupertinoPageRoute(builder: (_) => AlbumsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _artistBlock(String heading, List<Artist> artists, Set seenArtistIds) {
    return HorizontalCardScroller(
      headingText: heading,
      cards: <Widget>[
        ...artists.map((artist) =>
            ArtistCard(artist: artist, asHero: seenArtistIds.add(artist.id))),
        PlaceholderCard(
          icon: CupertinoIcons.music_mic,
          circular: true,
          onPressed: () => Navigator.of(context).push(
            CupertinoPageRoute(builder: (_) => const ArtistsScreen()),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OverviewProvider>(
      builder: (_, overviewProvider, __) {
        if (_loading) return const HomeScreenPlaceholder();
        if (_errored) return OopsBox(onRetry: fetchData);

        final op = overviewProvider;

        // Grant the hero animation to only the first card per entity, so the
        // same album/artist appearing in several blocks doesn't produce
        // duplicate hero tags within the route.
        final seenAlbumIds = <dynamic>{};
        final seenArtistIds = <dynamic>{};

        // Default order mirrors koel web's default home layout (minus the
        // recently-played section, which the mobile app pins to the top).
        final defaultBlocks = <_HomeBlock>[
          if (op.recentlyAddedAlbums.isNotEmpty)
            _HomeBlock('recently-added-albums',
                _albumBlock('Latest Albums', op.recentlyAddedAlbums, seenAlbumIds)),
          if (op.similarSongs.isNotEmpty)
            _HomeBlock('similar-songs',
                _songBlock('You Might Also Like', op.similarSongs)),
          if (op.mostPlayedAlbums.isNotEmpty)
            _HomeBlock('most-played-albums',
                _albumBlock('Top Albums', op.mostPlayedAlbums, seenAlbumIds)),
          if (op.mostPlayedSongs.isNotEmpty)
            _HomeBlock('most-played-songs',
                _songBlock('Most Played', op.mostPlayedSongs)),
          if (op.mostPlayedArtists.isNotEmpty)
            _HomeBlock('most-played-artists',
                _artistBlock('Top Artists', op.mostPlayedArtists, seenArtistIds)),
          if (op.recentlyAddedSongs.isNotEmpty)
            _HomeBlock('recently-added-songs',
                _songBlock('New Songs', op.recentlyAddedSongs)),
          if (op.recentlyAddedArtists.isNotEmpty)
            _HomeBlock(
                'recently-added-artists',
                _artistBlock(
                    'New Artists', op.recentlyAddedArtists, seenArtistIds)),
          if (op.leastPlayedSongs.isNotEmpty)
            _HomeBlock('least-played-songs',
                _songBlock('Hidden Gems', op.leastPlayedSongs)),
          if (op.randomSongs.isNotEmpty)
            _HomeBlock(
                'random-songs', _songBlock('Random Songs', op.randomSongs)),
          if (op.randomAlbums.isNotEmpty)
            _HomeBlock('random-albums',
                _albumBlock('Random Albums', op.randomAlbums, seenAlbumIds)),
          if (op.randomArtists.isNotEmpty)
            _HomeBlock('random-artists',
                _artistBlock('Random Artists', op.randomArtists, seenArtistIds)),
        ];

        final savedOrder =
            context.read<AuthProvider>().maybeAuthUser?.homeBlocksOrder ??
                const <String>[];

        final blocks = orderByHomeBlocksPreference<_HomeBlock>(
          defaultBlocks,
          (block) => block.id,
          savedOrder,
        )
            .map(
              (block) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: block.widget,
              ),
            )
            .toList();

        return Scaffold(
          body: CupertinoTheme(
            data: const CupertinoThemeData(
              primaryColor: AppColors.white,
              barBackgroundColor: AppColors.staticScreenHeaderBackground,
            ),
            child: PullToRefresh(
              onRefresh: () => context.read<OverviewProvider>().refresh(),
              child: CustomScrollView(
                slivers: overviewProvider.isEmpty
                    ? [SliverToBoxAdapter(child: const EmptyHomeScreen())]
                    : <Widget>[
                        CupertinoSliverNavigationBar(
                          backgroundColor:
                              AppColors.staticScreenHeaderBackground,
                          largeTitle: const LargeTitle(text: 'Home'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.of(context).push(CupertinoPageRoute(
                                    settings: const RouteSettings(
                                      name: RecentlyPlayedScreen.routeName,
                                    ),
                                    builder: (_) =>
                                        const RecentlyPlayedScreen(),
                                  ));
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
                              initialPlayables:
                                  overviewProvider.recentlyPlayedSongs,
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
  final List<Playable> initialPlayables;

  const HomeRecentlyPlayedSection({Key? key, required this.initialPlayables})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _HomeRecentlyPlayedSectionState();
}

class _HomeRecentlyPlayedSectionState extends State<HomeRecentlyPlayedSection> {
  @override
  Widget build(BuildContext context) {
    return Consumer<RecentlyPlayedProvider>(
      builder: (_, overviewProvider, __) {
        final playables = overviewProvider.playables.isNotEmpty
            ? overviewProvider.playables
                .getRange(0, min(4, overviewProvider.playables.length))
            : widget.initialPlayables
                .getRange(0, min(4, widget.initialPlayables.length));

        return playables.isEmpty
            ? SizedBox.shrink()
            : SimplePlayableList(playables: playables);
      },
    );
  }
}

class EmptyHomeScreen extends StatelessWidget {
  const EmptyHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.music_note,
              size: 100,
              color: AppColors.white,
            ),
            const SizedBox(height: 16),
            const Text(
              'No activities… yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pull down to refresh this screen.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

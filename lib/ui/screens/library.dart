import 'package:app/constants/constants.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/screens/screens.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:app/utils/features.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

class LibraryScreen extends StatelessWidget {
  static const routeName = '/library';

  const LibraryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final overviewProvider = context.watch<OverviewProvider>();
    final recentlyAddedSongs = overviewProvider.recentlyAddedSongs;
    final mostPlayedSongs = overviewProvider.mostPlayedSongs;

    final menuItems = ListTile.divideTiles(
      context: context,
      tiles: <Widget>[
        LibraryMenuItem(
          icon: CupertinoIcons.music_note,
          label: 'Songs',
          onTap: () => Navigator.of(context).push(
            CupertinoPageRoute(builder: (_) => const SongsScreen()),
          ),
        ),
        LibraryMenuItem(
          icon: CupertinoIcons.heart_fill,
          label: 'Favorites',
          onTap: () => Navigator.of(context).push(
            CupertinoPageRoute(builder: (_) => const FavoritesScreen()),
          ),
        ),
        LibraryMenuItem(
          icon: CupertinoIcons.music_note_list,
          label: 'Playlists',
          onTap: () => Navigator.of(context).push(
            CupertinoPageRoute(builder: (_) => const PlaylistsScreen()),
          ),
        ),
        LibraryMenuItem(
          icon: CupertinoIcons.music_mic,
          label: 'Artists',
          onTap: () => Navigator.of(context).push(
            CupertinoPageRoute(builder: (_) => const ArtistsScreen()),
          ),
        ),
        LibraryMenuItem(
          icon: CupertinoIcons.music_albums,
          label: 'Albums',
          onTap: () => Navigator.of(context).push(
            CupertinoPageRoute(builder: (_) => const AlbumsScreen()),
          ),
        ),
        if (Feature.podcasts.isSupported())
          LibraryMenuItem(
            icon: LucideIcons.podcast,
            label: 'Podcasts',
            onTap: () => Navigator.of(context).push(
              CupertinoPageRoute(builder: (_) => const PodcastsScreen()),
            ),
          ),
        LibraryMenuItem(
          icon: CupertinoIcons.cloud_download_fill,
          label: 'Downloaded',
          onTap: () => Navigator.of(context).push(
            CupertinoPageRoute(builder: (_) => DownloadedScreen()),
          ),
        ),
      ],
    ).toList();

    return Scaffold(
      body: CupertinoTheme(
        data: CupertinoThemeData(primaryColor: Colors.white),
        child: GradientDecoratedContainer(
          child: CustomScrollView(
            slivers: <Widget>[
              const CupertinoSliverNavigationBar(
                backgroundColor: AppColors.staticScreenHeaderBackground,
                largeTitle: const LargeTitle(text: 'Library'),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 0.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(menuItems),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.hPadding,
                  24,
                  AppDimensions.hPadding,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: const Heading5(text: 'Recently added'),
                ),
              ),
              recentlyAddedSongs.isEmpty
                  ? const SliverToBoxAdapter(child: SizedBox.shrink())
                  : SliverPlayableList(playables: recentlyAddedSongs),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.hPadding,
                  24,
                  AppDimensions.hPadding,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: const Heading5(text: 'Most played'),
                ),
              ),
              mostPlayedSongs.isEmpty
                  ? const SliverToBoxAdapter(child: SizedBox.shrink())
                  : SliverPlayableList(playables: mostPlayedSongs),
              const BottomSpace(),
            ],
          ),
        ),
      ),
    );
  }
}

class LibraryMenuItem extends StatelessWidget {
  final dynamic icon;
  final String label;
  final void Function() onTap;

  const LibraryMenuItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
  })  : assert(
          icon is IconData || icon is Widget,
          'icon must be of either IconData or Widget type.',
        ),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppDimensions.hPadding,
          ),
          horizontalTitleGap: 12,
          leading: icon is IconData ? Icon(icon, color: Colors.white54) : icon,
          title: Text(label, style: const TextStyle(fontSize: 20)),
          trailing: const Icon(
            CupertinoIcons.chevron_right,
            size: 18,
            color: Colors.white30,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

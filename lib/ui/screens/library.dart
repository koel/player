import 'package:app/constants/dimens.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/song_provider.dart';
import 'package:app/ui/screens/albums.dart';
import 'package:app/ui/screens/artists.dart';
import 'package:app/ui/screens/favorites.dart';
import 'package:app/ui/screens/playlists.dart';
import 'package:app/ui/screens/songs.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/headings.dart';
import 'package:app/ui/widgets/song_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  Widget menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        horizontalTitleGap: 0,
        leading: Icon(icon, color: Colors.white.withOpacity(.5)),
        title: Text(title, style: TextStyle(fontSize: 20)),
        trailing: Icon(
          CupertinoIcons.chevron_right,
          size: 18,
          color: Colors.white.withOpacity(.3),
        ),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final SongProvider songProvider = context.watch();
    List<Song> mostPlayedSongs = songProvider.mostPlayed(limit: 10);

    List<Widget> menuItems = ListTile.divideTiles(
      context: context,
      tiles: <Widget>[
        menuItem(
          icon: CupertinoIcons.heart_fill,
          title: 'Favorites',
          onTap: () {
            Navigator.of(context).push(CupertinoPageRoute<void>(
              builder: (_) => FavoritesScreen(previousPageTitle: 'Library'),
              title: 'Favorites',
            ));
          },
        ),
        menuItem(
          icon: CupertinoIcons.music_note_list,
          title: 'Playlists',
          onTap: () => gotoPlaylistsScreen(
            context,
            previousPageTitle: 'Library',
          ),
        ),
        menuItem(
          icon: CupertinoIcons.music_mic,
          title: 'Artists',
          onTap: () => gotoArtistsScreen(context, previousPageTitle: 'Library'),
        ),
        menuItem(
          icon: CupertinoIcons.music_albums,
          title: 'Albums',
          onTap: () => gotoAlbumsScreen(context, previousPageTitle: 'Library'),
        ),
        menuItem(
          icon: CupertinoIcons.music_note,
          title: 'Songs',
          onTap: () => gotoSongsScreen(context, previousPageTitle: 'Library'),
        ),
      ],
    ).toList();

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            backgroundColor: Colors.black,
            largeTitle: Text(
              'Library',
              style: TextStyle(color: Colors.white),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimens.horizontalPadding,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate(menuItems),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppDimens.horizontalPadding,
              24,
              AppDimens.horizontalPadding,
              0,
            ),
            sliver: SliverToBoxAdapter(child: Heading1(text: 'Recently Added')),
          ),
          mostPlayedSongs.length == 0
              ? SliverToBoxAdapter(child: SizedBox.shrink())
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) =>
                        SongRow(song: mostPlayedSongs[index]),
                    childCount: mostPlayedSongs.length,
                  ),
                ),
          SliverToBoxAdapter(child: bottomSpace()),
        ],
      ),
    );
  }
}

void gotoAlbumsScreen(BuildContext context, {String? previousPageTitle}) {
  Navigator.of(context).push(CupertinoPageRoute<void>(
    builder: (_) => AlbumsScreen(previousPageTitle: previousPageTitle),
    title: 'Albums',
  ));
}

void gotoArtistsScreen(BuildContext context, {String? previousPageTitle}) {
  Navigator.of(context).push(CupertinoPageRoute<void>(
    builder: (_) => ArtistsScreen(previousPageTitle: previousPageTitle),
    title: 'Artists',
  ));
}

void gotoSongsScreen(BuildContext context, {String? previousPageTitle}) {
  Navigator.of(context).push(CupertinoPageRoute<void>(
    builder: (_) => SongsScreen(previousPageTitle: previousPageTitle),
    title: 'Songs',
  ));
}

void gotoPlaylistsScreen(BuildContext context, {String? previousPageTitle}) {
  Navigator.of(context).push(CupertinoPageRoute<void>(
    builder: (_) => PlaylistsScreen(previousPageTitle: previousPageTitle),
    title: 'Playlists',
  ));
}

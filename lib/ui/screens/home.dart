import 'package:app/constants/dimens.dart';
import 'package:app/models/song.dart';
import 'package:app/models/user.dart';
import 'package:app/providers/album_provider.dart';
import 'package:app/providers/artist_provider.dart';
import 'package:app/providers/interaction_provider.dart';
import 'package:app/providers/song_provider.dart';
import 'package:app/providers/user_provider.dart';
import 'package:app/ui/screens/library.dart';
import 'package:app/ui/widgets/album_card.dart';
import 'package:app/ui/widgets/artist_card.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/headings.dart';
import 'package:app/ui/widgets/horizontal_card_scroller.dart';
import 'package:app/ui/widgets/simple_song_list.dart';
import 'package:app/ui/widgets/song_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    late User _authUser = context.watch<UserProvider>().authUser;
    late SongProvider songProvider = context.watch();
    late ArtistProvider artistProvider = context.watch();
    late AlbumProvider albumProvider = context.watch();
    late InteractionProvider interactionProvider = context.watch();

    return SafeArea(
      child: Container(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: AppDimens.horizontalPadding),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.horizontalPadding,
                ),
                child: heading1(text: "Howdy, ${_authUser.name}!"),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.horizontalPadding,
                ),
                child: SimpleSongList(
                  songs: songProvider.recentlyAdded(),
                ),
              ),
              const SizedBox(height: 32),
              HorizontalCardScroller(
                headingText: 'Most played songs',
                cards: <Widget>[
                  ...songProvider
                      .mostPlayed()
                      .map((song) => SongCard(song: song)),
                  PlaceholderCard(
                    icon: CupertinoIcons.music_note,
                    onPressed: () => gotoSongsScreen(context),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.horizontalPadding,
                ),
                child: SimpleSongList(
                  songs: interactionProvider.getRandomFavorites(limit: 5),
                  headingText: 'From your favorites',
                ),
              ),
              const SizedBox(height: 32),
              HorizontalCardScroller(
                headingText: 'Top albums',
                cards: <Widget>[
                  ...albumProvider
                      .mostPlayed()
                      .map((album) => AlbumCard(album: album)),
                  PlaceholderCard(
                    icon: CupertinoIcons.music_albums,
                    onPressed: () => gotoAlbumsScreen(context),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              HorizontalCardScroller(
                headingText: 'Top artists',
                cards: <Widget>[
                  ...artistProvider
                      .mostPlayed()
                      .map((artist) => ArtistCard(artist: artist)),
                  PlaceholderCard(
                    icon: CupertinoIcons.music_mic,
                    onPressed: () => gotoArtistsScreen(context),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.horizontalPadding,
                ),
                child: SimpleSongList(
                  songs: songProvider.leastPlayed(limit: 5),
                  headingText: 'Hidden gems',
                ),
              ),
              bottomSpace(),
            ],
          ),
        ),
      ),
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
          padding: const EdgeInsets.only(left: AppDimens.horizontalPadding),
          child: heading1(text: 'Most played'),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ...songs.expand(
                (song) => [
                  const SizedBox(width: AppDimens.horizontalPadding),
                  SongCard(song: song),
                ],
              ),
              const SizedBox(width: AppDimens.horizontalPadding),
              PlaceholderCard(
                icon: CupertinoIcons.music_note,
                onPressed: () => gotoSongsScreen(context),
              ),
              const SizedBox(width: AppDimens.horizontalPadding),
            ],
          ),
        ),
      ],
    );
  }
}

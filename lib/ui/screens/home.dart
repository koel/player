import 'package:app/constants/dimens.dart';
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
import 'package:app/ui/widgets/song_card.dart';
import 'package:app/ui/widgets/song_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late User _authUser = context.watch<UserProvider>().authUser;
  late SongProvider songProvider = context.watch();
  late ArtistProvider artistProvider = context.watch();
  late AlbumProvider albumProvider = context.watch();
  late InteractionProvider interactionProvider = context.watch();

  Widget placeholderCard({required IconData icon, VoidCallback? onPressed}) {
    return SizedBox(
      height: 144,
      width: 144,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.1),
          borderRadius: BorderRadius.all(Radius.circular(12)),
          border: Border.all(color: Colors.white.withOpacity(.1)),
        ),
        child: IconButton(
          onPressed: onPressed,
          iconSize: 32,
          icon: Icon(icon),
        ),
      ),
    );
  }

  Widget mostPlayedSongs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(left: AppDimens.horizontalPadding),
          child: Heading1(text: 'Most played songs'),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ...songProvider.mostPlayed().expand(
                    (song) => [
                      SizedBox(width: AppDimens.horizontalPadding),
                      SongCard(song: song),
                    ],
                  ),
              SizedBox(width: AppDimens.horizontalPadding),
              placeholderCard(
                icon: CupertinoIcons.music_note,
                onPressed: () => gotoSongsScreen(context),
              ),
              SizedBox(width: AppDimens.horizontalPadding),
            ],
          ),
        ),
      ],
    );
  }

  Widget leastPlayedSongs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Heading1(text: 'Hidden gems'),
        ...songProvider
            .leastPlayed(limit: 6)
            .map(
              (song) => SongRow(
                song: song,
                bordered: false,
                padding: EdgeInsets.symmetric(horizontal: 0),
              ),
            )
            .toList(),
      ],
    );
  }

  Widget topAlbums() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(left: AppDimens.horizontalPadding),
          child: Heading1(text: 'Top albums'),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ...albumProvider.mostPlayed().expand(
                    (album) => <Widget>[
                      SizedBox(width: AppDimens.horizontalPadding),
                      AlbumCard(album: album),
                    ],
                  ),
              SizedBox(width: AppDimens.horizontalPadding),
              placeholderCard(
                icon: CupertinoIcons.music_albums,
                onPressed: () => gotoAlbumsScreen(context),
              ),
              SizedBox(width: AppDimens.horizontalPadding),
            ],
          ),
        ),
      ],
    );
  }

  Widget topArtists() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(left: AppDimens.horizontalPadding),
          child: Heading1(text: 'Top artists'),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...artistProvider.mostPlayed().expand(
                    (artist) => <Widget>[
                      SizedBox(width: AppDimens.horizontalPadding),
                      ArtistCard(artist: artist),
                    ],
                  ),
              SizedBox(width: AppDimens.horizontalPadding),
              placeholderCard(
                icon: CupertinoIcons.music_mic,
                onPressed: () => gotoArtistsScreen(context),
              ),
              SizedBox(width: AppDimens.horizontalPadding),
            ],
          ),
        ),
      ],
    );
  }

  Widget recentlyAdded() {
    return Column(
      children: songProvider
          .recentlyAdded()
          .map(
            (song) => SongRow(
              song: song,
              bordered: false,
              padding: EdgeInsets.symmetric(horizontal: 0),
            ),
          )
          .toList(),
    );
  }

  Widget fromYourFavorites() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Heading1(text: 'From your favorites'),
        ...interactionProvider
            .getRandomFavorites(limit: 6)
            .map(
              (song) => SongRow(
                song: song,
                bordered: false,
                padding: EdgeInsets.symmetric(horizontal: 0),
              ),
            )
            .toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: AppDimens.horizontalPadding,
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimens.horizontalPadding,
                ),
                child: Heading1(text: "Howdy, ${_authUser.name}!"),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimens.horizontalPadding,
                ),
                child: recentlyAdded(),
              ),
              SizedBox(height: 32),
              mostPlayedSongs(),
              SizedBox(height: 32),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimens.horizontalPadding,
                ),
                child: fromYourFavorites(),
              ),
              SizedBox(height: 32),
              topAlbums(),
              SizedBox(height: 32),
              topArtists(),
              SizedBox(height: 32),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimens.horizontalPadding,
                ),
                child: leastPlayedSongs(),
              ),
              bottomSpace(),
            ],
          ),
        ),
      ),
    );
  }
}

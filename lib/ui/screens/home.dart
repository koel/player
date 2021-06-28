import 'package:app/constants/dimens.dart';
import 'package:app/models/user.dart';
import 'package:app/providers/album_provider.dart';
import 'package:app/providers/artist_provider.dart';
import 'package:app/providers/song_provider.dart';
import 'package:app/providers/user_provider.dart';
import 'package:app/ui/widgets/album_card.dart';
import 'package:app/ui/widgets/artist_card.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/headings.dart';
import 'package:app/ui/widgets/song_card.dart';
import 'package:app/ui/widgets/song_row.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late User _authUser = context.watch<UserProvider>().authUser;
  late SongProvider songProvider = context.watch<SongProvider>();
  late ArtistProvider artistProvider = context.watch<ArtistProvider>();
  late AlbumProvider albumProvider = context.watch<AlbumProvider>();

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
            children: <Widget>[
              ...songProvider.mostPlayed().expand(
                    (song) => [
                      SizedBox(width: AppDimens.horizontalPadding),
                      SongCard(song: song),
                    ],
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Widget leastPlayedSongs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(left: AppDimens.horizontalPadding),
          child: Heading1(text: 'Give these a try'),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              ...songProvider.leastPlayed().expand(
                    (song) => <Widget>[
                      SizedBox(width: AppDimens.horizontalPadding),
                      SongCard(song: song),
                    ],
                  ),
            ],
          ),
        ),
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
            children: <Widget>[
              ...albumProvider.mostPlayed().expand(
                    (album) => <Widget>[
                      SizedBox(width: AppDimens.horizontalPadding),
                      AlbumCard(album: album),
                    ],
                  ),
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
            children: [
              ...artistProvider.mostPlayed().expand(
                    (artist) => <Widget>[
                      SizedBox(width: AppDimens.horizontalPadding),
                      ArtistCard(artist: artist),
                    ],
                  ),
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
              topAlbums(),
              SizedBox(height: 32),
              topArtists(),
              SizedBox(height: 32),
              leastPlayedSongs(),
              bottomSpace(),
            ],
          ),
        ),
      ),
    );
  }
}

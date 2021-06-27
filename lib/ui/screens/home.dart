import 'package:app/models/album.dart';
import 'package:app/models/artist.dart';
import 'package:app/models/song.dart';
import 'package:app/models/user.dart';
import 'package:app/providers/album_provider.dart';
import 'package:app/providers/artist_provider.dart';
import 'package:app/providers/song_provider.dart';
import 'package:app/providers/user_provider.dart';
import 'package:app/ui/widgets/album_card.dart';
import 'package:app/ui/widgets/artist_card.dart';
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
        Heading1(text: 'Most played songs'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              ...songProvider.mostPlayed().expand(
                    (song) => [
                      SongCard(song: song),
                      SizedBox(width: 12),
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
        Heading1(text: 'Give these a try'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              ...songProvider.leastPlayed().expand(
                    (song) => <Widget>[
                      SongCard(song: song),
                      SizedBox(width: 12),
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
        Heading1(text: 'Top albums'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              ...albumProvider.mostPlayed().expand(
                    (album) => <Widget>[
                      AlbumCard(album: album),
                      SizedBox(width: 12),
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
        Heading1(text: 'Top artists'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...artistProvider.mostPlayed().expand(
                    (artist) => <Widget>[
                      ArtistCard(artist: artist),
                      SizedBox(width: 12),
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
              SizedBox(height: 24),
              Heading1(text: "Howdy, ${_authUser.name}!"),
              recentlyAdded(),
              SizedBox(height: 32),
              mostPlayedSongs(),
              SizedBox(height: 32),
              topAlbums(),
              SizedBox(height: 32),
              topArtists(),
              SizedBox(height: 32),
              leastPlayedSongs(),
              SizedBox(height: 128), // cheap bottom padding
            ],
          ),
        ),
      ),
    );
  }
}

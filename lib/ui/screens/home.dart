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
  late User _authUser = Provider.of<UserProvider>(context).authUser;
  late List<Song> _recentlyAddedSongs =
      Provider.of<SongProvider>(context).recentlyAdded();
  late List<Song> _mostPlayedSongs =
      Provider.of<SongProvider>(context).mostPlayed();
  late List<Artist> _topArtists =
      Provider.of<ArtistProvider>(context).mostPlayed();
  late List<Album> _topAlbums =
      Provider.of<AlbumProvider>(context).mostPlayed();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Heading1(text: "Howdy, ${_authUser.name}!"),
              RecentlyAdded(songs: _recentlyAddedSongs),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MostPlayedSongs(songs: _mostPlayedSongs),
                  TopAlbums(albums: _topAlbums),
                  TopArtists(artists: _topArtists),
                  SizedBox(height: 32), // cheap bottom padding
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MostPlayedSongs extends StatelessWidget {
  final List<Song> songs;

  const MostPlayedSongs({
    Key? key,
    required this.songs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Heading1(text: 'Most played songs'),
        Container(
          height: 225,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...songs.expand(
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
}

class TopAlbums extends StatelessWidget {
  final List<Album> albums;

  const TopAlbums({
    Key? key,
    required this.albums,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Heading1(text: 'Top albums'),
        Container(
          height: 225,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...albums.expand(
                (album) => [
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
}

class TopArtists extends StatelessWidget {
  final List<Artist> artists;

  const TopArtists({
    Key? key,
    required this.artists,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Heading1(text: 'Top artists'),
        Container(
          height: 225,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...artists.expand(
                (artist) => [
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
}

class RecentlyAdded extends StatelessWidget {
  final List<Song> songs;

  RecentlyAdded({
    Key? key,
    required this.songs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: songs
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
}

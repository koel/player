import 'package:app/models/artist.dart';
import 'package:app/models/song.dart';
import 'package:app/models/user.dart';
import 'package:app/providers/artist_provider.dart';
import 'package:app/providers/song_provider.dart';
import 'package:app/providers/user_provider.dart';
import 'package:app/ui/widgets/artist_card.dart';
import 'package:app/ui/widgets/headings.dart';
import 'package:app/ui/widgets/song_card.dart';
import 'package:app/ui/widgets/song_item.dart';
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
  late List<Artist> _mostPlayedArtists =
      Provider.of<ArtistProvider>(context).mostPlayed();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Heading1(text: "Howdy, ${_authUser.name}!"),
              RecentlyAdded(recentlyAddedSongs: _recentlyAddedSongs),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Heading1(text: 'Most played songs'),
                  Container(
                    height: 225,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ..._mostPlayedSongs.expand((song) => [
                              SongCard(song: song),
                              SizedBox(width: 12),
                            ]),
                      ],
                    ),
                  ),
                  Heading1(text: 'Top artists'),
                  Container(
                    height: 225,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ..._mostPlayedArtists.expand((artist) => [
                              ArtistCard(artist: artist),
                              SizedBox(width: 12),
                            ]),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecentlyAdded extends StatelessWidget {
  const RecentlyAdded({
    Key? key,
    required List<Song> recentlyAddedSongs,
  })  : _recentlyAddedSongs = recentlyAddedSongs,
        super(key: key);

  final List<Song> _recentlyAddedSongs;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ..._recentlyAddedSongs.expand(
          (song) => [
            SongItem(song),
            SizedBox(height: 12),
          ],
        ),
      ],
    );
  }
}

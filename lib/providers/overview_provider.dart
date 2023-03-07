import 'package:app/models/album.dart';
import 'package:app/models/artist.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/album_provider.dart';
import 'package:app/providers/artist_provider.dart';
import 'package:app/providers/recently_played_provider.dart';
import 'package:app/providers/song_provider.dart';
import 'package:app/utils/api_request.dart';
import 'package:flutter/foundation.dart';

class OverviewProvider with ChangeNotifier {
  SongProvider songProvider;
  AlbumProvider albumProvider;
  ArtistProvider artistProvider;
  RecentlyPlayedProvider recentlyPlayedProvider;

  List<Song> mostPlayedSongs = [];
  List<Song> recentlyAddedSongs = [];
  List<Song> recentlyPlayedSongs = [];
  List<Album> recentlyAddedAlbums = [];
  List<Album> mostPlayedAlbums = [];
  List<Artist> mostPlayedArtists = [];

  OverviewProvider({
    required this.songProvider,
    required this.albumProvider,
    required this.artistProvider,
    required this.recentlyPlayedProvider,
  });

  Future<void> fetchOverview() async {
    final Map<String, dynamic> response = await get('overview');

    mostPlayedSongs = parseSongsFromJson(response['most_played_songs']);
    recentlyAddedSongs = parseSongsFromJson(response['recently_added_songs']);
    recentlyPlayedSongs = parseSongsFromJson(response['recently_played_songs']);

    List<Album> _mostPlayedAlbums = response['most_played_albums']
        .map<Album>((j) => Album.fromJson(j))
        .toList();

    mostPlayedAlbums = albumProvider.syncWithVault(_mostPlayedAlbums);

    List<Artist> _mostPlayedArtist = response['most_played_artists']
        .map<Artist>((j) => Artist.fromJson(j))
        .toList();

    mostPlayedArtists = artistProvider.syncWithVault(_mostPlayedArtist);

    notifyListeners();
  }

  parseSongsFromJson(dynamic json) {
    List<Song> _songs = json.map<Song>((j) => Song.fromJson(j)).toList();

    return songProvider.syncWithVault(_songs);
  }
}

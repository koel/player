import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/utils/api_request.dart';
import 'package:flutter/foundation.dart';

class OverviewProvider with ChangeNotifier, StreamSubscriber {
  final PlayableProvider _playableProvider;
  final AlbumProvider _albumProvider;
  final ArtistProvider _artistProvider;
  final RecentlyPlayedProvider _recentlyPlayedProvider;

  final mostPlayedSongs = <Playable>[];
  final recentlyAddedSongs = <Playable>[];
  final recentlyPlayedSongs = <Playable>[];
  final leastPlayedSongs = <Playable>[];
  final randomSongs = <Playable>[];
  final similarSongs = <Playable>[];
  final mostPlayedAlbums = <Album>[];
  final recentlyAddedAlbums = <Album>[];
  final randomAlbums = <Album>[];
  final mostPlayedArtists = <Artist>[];
  final recentlyAddedArtists = <Artist>[];
  final randomArtists = <Artist>[];

  late final List<List<dynamic>> _allSections = [
    mostPlayedSongs,
    recentlyAddedSongs,
    recentlyPlayedSongs,
    leastPlayedSongs,
    randomSongs,
    similarSongs,
    mostPlayedAlbums,
    recentlyAddedAlbums,
    randomAlbums,
    mostPlayedArtists,
    recentlyAddedArtists,
    randomArtists,
  ];

  OverviewProvider({
    required playableProvider,
    required albumProvider,
    required artistProvider,
    required recentlyPlayedProvider,
  })  : _playableProvider = playableProvider,
        _albumProvider = albumProvider,
        _artistProvider = artistProvider,
        _recentlyPlayedProvider = recentlyPlayedProvider {
    subscribe(AuthProvider.userLoggedOutStream.listen((_) {
      for (final section in _allSections) section.clear();
      notifyListeners();
    }));
  }

  bool get isEmpty => _allSections.every((section) => section.isEmpty);

  Future<void> refresh() async {
    final Map<String, dynamic> response = await get('overview');

    _fill(mostPlayedSongs, _parseSongs(response['most_played_songs']));
    _fill(recentlyAddedSongs, _parseSongs(response['recently_added_songs']));
    _fill(recentlyPlayedSongs, _parseSongs(response['recently_played_songs']));
    _fill(leastPlayedSongs, _parseSongs(response['least_played_songs']));
    _fill(randomSongs, _parseSongs(response['random_songs']));
    _fill(similarSongs, _parseSongs(response['similar_songs']));

    _fill(mostPlayedAlbums, _parseAlbums(response['most_played_albums']));
    _fill(recentlyAddedAlbums, _parseAlbums(response['recently_added_albums']));
    _fill(randomAlbums, _parseAlbums(response['random_albums']));

    _fill(mostPlayedArtists, _parseArtists(response['most_played_artists']));
    _fill(recentlyAddedArtists,
        _parseArtists(response['recently_added_artists']));
    _fill(randomArtists, _parseArtists(response['random_artists']));

    _recentlyPlayedProvider.seed(recentlyPlayedSongs);

    notifyListeners();
  }

  List<Playable> _parseSongs(dynamic json) =>
      _playableProvider.parseFromJson(json ?? const []);

  List<Album> _parseAlbums(dynamic json) => _albumProvider.syncWithVault(
        ((json ?? const []) as List)
            .map<Album>((j) => Album.fromJson(j))
            .toList(),
      );

  List<Artist> _parseArtists(dynamic json) => _artistProvider.syncWithVault(
        ((json ?? const []) as List)
            .map<Artist>((j) => Artist.fromJson(j))
            .toList(),
      );

  void _fill<T>(List<T> target, List<T> source) {
    target
      ..clear()
      ..addAll(source);
  }
}

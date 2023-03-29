import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/utils/api_request.dart';
import 'package:flutter/foundation.dart';

class SearchResult {
  var songs = <Song>[];
  var artists = <Artist>[];
  var albums = <Album>[];

  SearchResult({
    this.songs = const [],
    this.artists = const [],
    this.albums = const [],
  });
}

class SearchProvider with ChangeNotifier {
  final SongProvider _songProvider;
  final AlbumProvider _albumProvider;
  final ArtistProvider _artistProvider;
  final AppStateProvider _appState;

  SearchProvider({
    required songProvider,
    required artistProvider,
    required albumProvider,
    required appState,
  })  : _songProvider = songProvider,
        _artistProvider = artistProvider,
        _albumProvider = albumProvider,
        _appState = appState;

  Future<SearchResult> searchExcerpts({required String keywords}) async {
    final cacheKey = ['search.excerpts', keywords];
    if (_appState.has(cacheKey)) return _appState.get(cacheKey);

    final res = await get('search?q=$keywords');

    final songs = _songProvider.syncWithVault(
        res['songs'].map<Song>((j) => Song.fromJson(j)).toList());
    final artists = _artistProvider.syncWithVault(
        res['artists'].map<Artist>((j) => Artist.fromJson(j)).toList());
    final albums = _albumProvider.syncWithVault(
        res['albums'].map<Album>((j) => Album.fromJson(j)).toList());

    return _appState.set<SearchResult>(
      cacheKey,
      SearchResult(
        songs: songs,
        artists: artists,
        albums: albums,
      ),
    );
  }

  Future<List<Song>> searchSongs(String keywords) async {
    final cacheKey = ['search.songs', keywords];

    if (_appState.has(cacheKey)) return _appState.get(cacheKey);

    final res = await get('search/songs?q=$keywords');
    final songs = _songProvider
        .syncWithVault(res.map<Song>((j) => Song.fromJson(j)).toList());

    return _appState.set<List<Song>>(cacheKey, songs);
  }
}

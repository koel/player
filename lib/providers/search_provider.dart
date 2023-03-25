import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/utils/api_request.dart';
import 'package:flutter/foundation.dart';

class SearchResult {
  List<Song> songs;
  List<Artist> artists;
  List<Album> albums;

  SearchResult({
    required this.songs,
    required this.artists,
    required this.albums,
  });
}

class SearchProvider with ChangeNotifier {
  SongProvider _songProvider;
  AlbumProvider _albumProvider;
  ArtistProvider _artistProvider;
  AppStateProvider _appState;

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
    if (_appState.has('search.excerpts'))
      return _appState.get('search.excerpts');

    var res = await get('search?q=$keywords');

    List<Song> songs = _songProvider.syncWithVault(
        res['songs'].map<Song>((j) => Song.fromJson(j)).toList());
    List<Artist> artists = _artistProvider.syncWithVault(
        res['artists'].map<Artist>((j) => Artist.fromJson(j)).toList());
    List<Album> albums = _albumProvider.syncWithVault(
        res['albums'].map<Album>((j) => Album.fromJson(j)).toList());

    return _appState.set<SearchResult>(
        'search.excerpts',
        SearchResult(
          songs: songs,
          artists: artists,
          albums: albums,
        ));
  }

  Future<List<Song>> searchSongs(String query) async {
    if (_appState.has(['search.songs', query]))
      return _appState.get(['search.songs', query]);

    var res = await get('search/songs?q=$query');

    List<Song> songs = _songProvider
        .syncWithVault(res.map<Song>((j) => Song.fromJson(j)).toList());

    return _appState.set<List<Song>>(['search.songs', query], songs);
  }
}

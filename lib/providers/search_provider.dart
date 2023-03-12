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

  SearchProvider({
    required songProvider,
    required artistProvider,
    required albumProvider,
  })  : _songProvider = songProvider,
        _artistProvider = artistProvider,
        _albumProvider = albumProvider;

  Future<SearchResult> searchExcerpts({required String keywords}) async {
    var res = await get('search?q=$keywords');

    List<Song> songs = _songProvider.syncWithVault(
        res['songs'].map<Song>((j) => Song.fromJson(j)).toList());
    List<Artist> artists = _artistProvider.syncWithVault(
        res['artists'].map<Artist>((j) => Artist.fromJson(j)).toList());
    List<Album> albums = _albumProvider.syncWithVault(
        res['albums'].map<Album>((j) => Album.fromJson(j)).toList());

    return SearchResult(
      songs: songs,
      artists: artists,
      albums: albums,
    );
  }
}

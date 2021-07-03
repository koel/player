import 'package:app/models/album.dart';
import 'package:app/models/artist.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/album_provider.dart';
import 'package:app/providers/artist_provider.dart';
import 'package:app/providers/song_provider.dart';
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
    var results = await get('search?q=$keywords');
    List<String> songIds = results['results']['songs'].cast<String>();
    List<int> artistIds = results['results']['artists'].cast<int>();
    List<int> albumIds = results['results']['albums'].cast<int>();

    return SearchResult(
      songs: _songProvider.byIds(songIds),
      artists: _artistProvider.byIds(artistIds),
      albums: _albumProvider.byIds(albumIds),
    );
  }
}

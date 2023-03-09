import 'package:app/enums.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/widgets/app_bar.dart';
import 'package:app/utils/api_request.dart';
import 'package:app/values/values.dart';
import 'package:flutter/foundation.dart';

class SongProvider with ChangeNotifier {
  ArtistProvider artistProvider;
  AlbumProvider albumProvider;
  CacheProvider cacheProvider;
  AppStateProvider appState;
  late CoverImageStack coverImageStack;

  List<Song> songs = [];
  Map<String, Song> _vault = {};

  SongProvider({
    required this.artistProvider,
    required this.albumProvider,
    required this.cacheProvider,
    required this.appState,
  });

  List<Song> syncWithVault(dynamic _songs) {
    if (!(_songs is List<Song> || _songs is Song)) {
      throw Exception('Invalid type for songs. Must be List<Song> or Song.');
    }

    if (_songs is Song) {
      _songs = [_songs];
    }

    List<Song> synced = (_songs as List<Song>).map<Song>((remote) {
      Song? local = byId(remote.id);

      if (local == null) {
        _vault[remote.id] = remote;
        return remote;
      } else {
        return local.merge(remote);
      }
    }).toList();

    return synced;
  }

  Song? byId(String id) => _vault[id];

  List<Song> byIds(List<String> ids) {
    List<Song> songs = [];

    ids.forEach((id) {
      if (_vault.containsKey(id)) {
        songs.add(_vault[id]!);
      }
    });

    return songs;
  }

  Future<PaginationResult<Song>> paginate(
    String sortField,
    SortOrder sortOrder,
    int page,
  ) async {
    var res = await get(
      'songs?page=$page&sort=$sortField&order=${sortOrder.value}',
    );

    List<Song> items =
        res['data'].map<Song>((json) => Song.fromJson(json)).toList();

    List<Song> synced = syncWithVault(items);

    songs = [...songs, ...synced].toSet().toList();
    notifyListeners();

    return new PaginationResult(
      items: synced,
      nextPage: res['links']['next'] ? ++res['meta']['current_page'] : null,
    );
  }

  Future<List<Song>> fetchForArtist(int artistId) async {
    return _stateAwareFetch('artists/$artistId/songs');
  }

  Future<List<Song>> fetchForAlbum(int albumId) async {
    return _stateAwareFetch('albums/$albumId/songs');
  }

  Future<List<Song>> _stateAwareFetch(String url) async {
    var res = await get(url);
    List<Song> items = res.map<Song>((json) => Song.fromJson(json)).toList();
    appState.set(url, items);

    return syncWithVault(items);
  }
}

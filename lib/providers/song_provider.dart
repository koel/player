import 'package:app/enums.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/widgets/app_bar.dart';
import 'package:app/utils/api_request.dart';
import 'package:app/values/values.dart';
import 'package:flutter/foundation.dart';

class SongProvider with ChangeNotifier {
  late DownloadProvider _downloadProvider;
  late AppStateProvider _appState;
  late CoverImageStack coverImageStack;

  List<Song> songs = [];
  Map<String, Song> _vault = {};

  SongProvider({
    required DownloadProvider downloadProvider,
    required AppStateProvider appState,
  }) {
    _downloadProvider = downloadProvider;
    _appState = appState;

    syncDownloadedSongs();
  }

  Future<void> syncDownloadedSongs() async {
    await _downloadProvider.collectDownloads();
    syncWithVault(_downloadProvider.songs);
  }

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

  Future<PaginationResult<Song>> paginate(SongPaginationConfig config) async {
    var res = await get(
      'songs?page=${config.page}&sort=${config.sortField}&order=${config.sortOrder.value}',
    );

    List<Song> items = res['data'].map<Song>((j) => Song.fromJson(j)).toList();
    List<Song> synced = syncWithVault(items);

    songs = [...songs, ...synced].toSet().toList();
    notifyListeners();

    return new PaginationResult(
      items: synced,
      nextPage:
          res['links']['next'] == null ? null : ++res['meta']['current_page'],
    );
  }

  Future<List<Song>> fetchForArtist(
    int artistId, {
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) _appState.delete(['artist.songs', artistId]);

    return _stateAwareFetch(
      'artists/$artistId/songs',
      ['artist.songs', artistId],
    );
  }

  Future<List<Song>> fetchForAlbum(
    int albumId, {
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) _appState.delete(['album.songs', albumId]);

    return _stateAwareFetch(
      'albums/$albumId/songs',
      ['album.songs', albumId],
    );
  }

  Future<List<Song>> fetchForPlaylist(
    int playlistId, {
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) _appState.delete(['playlist.songs', playlistId]);

    return _stateAwareFetch(
      'playlists/$playlistId/songs',
      ['playlist.songs', playlistId],
    );
  }

  Future<List<Song>> _stateAwareFetch(String url, Object stateKey) async {
    if (_appState.has(stateKey)) return _appState.get(stateKey);

    var res = await get(url);
    List<Song> items = res.map<Song>((json) => Song.fromJson(json)).toList();
    _appState.set(stateKey, items);

    return syncWithVault(items);
  }

  Future<List<Song>> fetchRandom({int limit = 500}) async {
    var res = await get('queue/fetch?order=rand&limit=$limit');
    List<Song> items = res.map<Song>((json) => Song.fromJson(json)).toList();

    return syncWithVault(items);
  }

  Future<List<Song>> fetchInOrder({
    String sortField = 'title',
    SortOrder order = SortOrder.asc,
    int limit = 500,
  }) async {
    var res = await get(
      'queue/fetch?order=${order.value}&sort=$sortField&limit=$limit',
    );
    List<Song> items = res.map<Song>((json) => Song.fromJson(json)).toList();

    return syncWithVault(items);
  }
}

class SongPaginationConfig {
  String _sortField;
  SortOrder _sortOrder;
  int? page;

  SongPaginationConfig({
    String sortField = 'title',
    SortOrder sortOrder = SortOrder.asc,
    this.page = 1,
  })  : _sortField = sortField,
        _sortOrder = sortOrder;

  String get sortField => _sortField;

  SortOrder get sortOrder => _sortOrder;

  set sortField(String field) {
    if (field != _sortField) {
      _sortOrder = SortOrder.asc;
      page = 1;
    }

    _sortField = field;
  }

  set sortOrder(SortOrder order) {
    if (order != _sortOrder) {
      page = 1;
    }

    _sortOrder = order;
  }
}

import 'package:app/app_state.dart';
import 'package:app/enums.dart';
import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/utils/api_request.dart';
import 'package:app/values/values.dart';
import 'package:flutter/foundation.dart';

class PlayableProvider with ChangeNotifier, StreamSubscriber {
  var playables = <Playable>[];
  final _vault = <String, Playable>{};

  PlayableProvider() {
    subscribe(AuthProvider.userLoggedOutStream.listen((_) {
      playables.clear();
      _vault.clear();
      notifyListeners();
    }));
  }

  List<Playable> syncWithVault(dynamic _playables) {
    assert(_playables is List<Playable> || _playables is Playable);

    if (_playables is Playable) {
      _playables = [_playables];
    }

    return (_playables as List<Playable>)
        .map<Playable>((remote) {
          final local = byId(remote.id);

          if (local == null) {
            _vault[remote.id] = remote;
            return remote;
          } else {
            return local.merge(remote);
          }
        })
        .toSet()
        .toList();
  }

  Playable? byId(String id) => _vault[id];

  Future<PaginationResult<Playable>> paginate(
    PlayablePaginationConfig config,
  ) async {
    final res = await get(
      'songs'
      '?page=${config.page}'
      '&sort=${config.sortField}'
      '&order=${config.sortOrder.value}',
    );

    final items =
        res['data'].map<Playable>((j) => Playable.fromJson(j)).toList();
    final synced = syncWithVault(items);

    playables = [...playables, ...synced].toSet().toList();
    notifyListeners();

    return new PaginationResult(
      items: synced,
      nextPage:
          res['links']['next'] == null ? null : ++res['meta']['current_page'],
    );
  }

  Future<List<Playable>> fetchForArtist(
    dynamic artistId, {
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) AppState.delete(['artist.songs', artistId]);

    return _stateAwareFetch(
      'artists/$artistId/songs',
      ['artist.songs', artistId],
    );
  }

  Future<List<Playable>> fetchForAlbum(
    dynamic albumId, {
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) AppState.delete(['album.songs', albumId]);

    return _stateAwareFetch(
      'albums/$albumId/songs',
      ['album.songs', albumId],
    );
  }

  Future<List<Playable>> fetchForPlaylist(
    var playlistId, {
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) AppState.delete(['playlist.playables', playlistId]);

    return _stateAwareFetch(
      'playlists/$playlistId/songs',
      ['playlist.playables', playlistId],
    );
  }

  Future<List<Playable>> fetchForPodcast(
    String podcastId, {
    bool forceRefresh = false,
    bool getUpdates = false,
  }) async {
    if (forceRefresh) AppState.delete(['podcast.episodes', podcastId]);

    return _stateAwareFetch(
      'podcasts/$podcastId/episodes${getUpdates ? '?refresh=1' : ''}',
      ['podcast.episodes', podcastId],
    );
  }

  Future<List<Playable>> _stateAwareFetch(String url, Object cacheKey) async {
    if (AppState.has(cacheKey)) return AppState.get(cacheKey);
    return AppState.set(cacheKey, parseFromJson(await get(url)));
  }

  Future<List<Playable>> fetchRandom({int limit = 500}) async {
    final res = await get('queue/fetch?order=rand&limit=$limit');
    final items = res.map<Playable>((json) => Playable.fromJson(json)).toList();
    return syncWithVault(items);
  }

  Future<List<Playable>> fetchInOrder({
    String sortField = 'title',
    SortOrder order = SortOrder.asc,
    int limit = 500,
  }) async {
    final res = await get(
      'queue/fetch?order=${order.value}&sort=$sortField&limit=$limit',
    );
    final items = res.map<Playable>((json) => Playable.fromJson(json)).toList();
    return syncWithVault(items);
  }

  List<Playable> parseFromJson(dynamic json) {
    final playables = <Playable>[];

    json.forEach((j) {
      playables.add(Playable.fromJson(j));
    });

    return syncWithVault(playables).toList();
  }
}

class PlayablePaginationConfig {
  String _sortField;
  SortOrder _sortOrder;
  int? page;

  PlayablePaginationConfig({
    String sortField = 'title',
    SortOrder sortOrder = SortOrder.asc,
    this.page = 1,
  })  : _sortField = sortField,
        _sortOrder = sortOrder;

  String get sortField => _sortField;

  SortOrder get sortOrder => _sortOrder;

  PlayableSortConfig get sortConfig => PlayableSortConfig(
        field: _sortField,
        order: _sortOrder,
      );

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

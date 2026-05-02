import 'dart:async';

import 'package:app/enums.dart';
import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/artist_provider.dart';
import 'package:app/providers/auth_provider.dart';
import 'package:app/utils/api_request.dart';
import 'package:flutter/foundation.dart';

class AlbumProvider with ChangeNotifier, StreamSubscriber {
  var albums = <Album>[];
  final _vault = <dynamic, Album>{};
  var _page = 1;
  var _sortField = 'name';
  var _sortOrder = SortOrder.asc;

  /// Fires after [update] mutates an album in place. Other providers
  /// (e.g. PlayableProvider) listen to keep their denormalised
  /// `albumName` fields in sync.
  static final _renamedController = StreamController<Album>.broadcast();
  static final renamedStream = _renamedController.stream;

  String get sortField => _sortField;
  SortOrder get sortOrder => _sortOrder;

  set sortField(String field) {
    if (field != _sortField) {
      _sortOrder = SortOrder.asc;
    }
    _sortField = field;
  }

  set sortOrder(SortOrder order) {
    _sortOrder = order;
  }

  Album? byId(dynamic id) => _vault[id];

  AlbumProvider() {
    subscribe(AuthProvider.userLoggedOutStream.listen((_) {
      albums.clear();
      _vault.clear();
      _page = 1;

      notifyListeners();
    }));

    subscribe(ArtistProvider.renamedStream.listen(_onArtistRenamed));
  }

  void _onArtistRenamed(Artist artist) {
    var changed = false;
    for (final album in _vault.values) {
      if (album.artistId == artist.id && album.artistName != artist.name) {
        album.artistName = artist.name;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  List<Album> byIds(List<dynamic> ids) {
    final albums = <Album>[];

    ids.forEach((id) {
      if (_vault.containsKey(id)) {
        albums.add(_vault[id]!);
      }
    });

    return albums;
  }

  Future<Album> resolve(dynamic id, {bool forceRefresh = false}) async {
    if (!_vault.containsKey(id) || forceRefresh) {
      _vault[id] = Album.fromJson(await get('albums/$id'));
    }

    return _vault[id]!;
  }

  List<Album> syncWithVault(dynamic _albums) {
    assert(_albums is List<Album> || _albums is Album);

    if (_albums is Album) {
      _albums = [_albums];
    }

    List<Album> synced = (_albums as List<Album>)
        .map<Album>((remote) {
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

    notifyListeners();

    return synced;
  }

  Future<void> paginate() async {
    final res = await get(
      'albums?page=$_page&sort=$_sortField&order=${_sortOrder.value}',
    );

    final List<Album> _albums = (res['data'] as List)
        .map<Album>((album) => Album.fromJson(album))
        .toList();

    final List<Album> synced = syncWithVault(_albums);
    albums = [...albums, ...synced].toSet().toList();

    _page = res['links']['next'] == null ? 1 : ++res['meta']['current_page'];

    notifyListeners();
  }

  Future<void> refresh() {
    albums.clear();
    _page = 1;

    return paginate();
  }

  Future<void> toggleFavorite(Album album) async {
    // Optimistic flip + restore on failure.
    album.favorite = !album.favorite;
    notifyListeners();

    try {
      await post('favorites/toggle', data: {
        'type': 'album',
        'id': album.id,
      });
    } catch (_) {
      album.favorite = !album.favorite;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> update(
    Album album, {
    required String name,
    int? year,
  }) async {
    final response = await put('albums/${album.id}', data: {
      'name': name,
      'year': year,
    });

    final renamed = album.name != response['name'];

    album
      ..name = response['name']
      ..year = response['year'] == null
          ? null
          : int.parse(response['year'].toString());

    notifyListeners();

    if (renamed) _renamedController.add(album);
  }
}

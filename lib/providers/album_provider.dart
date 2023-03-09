import 'package:app/models/models.dart';
import 'package:app/utils/api_request.dart';
import 'package:flutter/foundation.dart';

class AlbumProvider with ChangeNotifier {
  List<Album> albums = [];
  Map<int, Album> _vault = {};
  int _page = 1;

  Album? byId(int id) => _vault[id];

  List<Album> byIds(List<int> ids) {
    List<Album> albums = [];

    ids.forEach((id) {
      if (_vault.containsKey(id)) {
        albums.add(_vault[id]!);
      }
    });

    return albums;
  }

  Future<Album> resolve(int id) async {
    if (!_vault.containsKey(id)) {
      _vault[id] = Album.fromJson(await get('albums/$id'));
    }

    return _vault[id]!;
  }

  List<Album> syncWithVault(dynamic _albums) {
    if (!(_albums is List<Album> || _albums is Album)) {
      throw Exception('Invalid type for albums. Must be List<Album> or Album.');
    }

    if (_albums is Album) {
      _albums = [_albums];
    }

    List<Album> synced = (_albums as List<Album>).map<Album>((remote) {
      Album? local = byId(remote.id);

      if (local == null) {
        _vault[remote.id] = remote;
        return remote;
      } else {
        return local.merge(remote);
      }
    }).toList();

    notifyListeners();

    return synced;
  }

  Future<void> paginate() async {
    // @todo - cache this
    var res = await get('albums?page=$_page');

    List<Album> _albums = (res['data'] as List)
        .map<Album>((album) => Album.fromJson(album))
        .toList();

    List<Album> synced = syncWithVault(_albums);
    albums = [...albums, ...synced].toSet().toList();

    _page = res['links']['next'] == null ? 1 : ++res['meta']['current_page'];

    notifyListeners();
  }
}

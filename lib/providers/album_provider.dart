import 'package:app/models/album.dart';
import 'package:app/utils/api_request.dart';
import 'package:app/values/parse_result.dart';
import 'package:flutter/foundation.dart';

import 'artist_provider.dart';

ParseResult parseAlbums(List<dynamic> data) {
  ParseResult result = ParseResult();
  data.forEach((json) => result.add(Album.fromJson(json), json['id']));

  return result;
}

class AlbumProvider with ChangeNotifier {
  late ArtistProvider artistProvider;
  List<Album> albums = [];
  Map<int, Album> vault = {};

  AlbumProvider({required this.artistProvider});

  Album? byId(int id) => vault[id];

  List<Album> byIds(List<int> ids) {
    List<Album> albums = [];

    ids.forEach((id) {
      if (vault.containsKey(id)) {
        albums.add(vault[id]!);
      }
    });

    return albums;
  }

  Future<Album> resolve(int id) async {
    if (vault.containsKey(id)) {
      return vault[id]!;
    }

    var json = await get('albums/$id');
    Album album = Album.fromJson(json);
    albums.add(album);
    vault[album.id] = album;
    notifyListeners();

    return album;
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
        albums.add(remote);
        vault[remote.id] = remote;
        return remote;
      } else {
        return local.merge(remote);
      }
    }).toList();

    notifyListeners();

    return synced;
  }
}

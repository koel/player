import 'package:app/models/album.dart';
import 'package:app/values/parse_result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'artist_provider.dart';

ParseResult parseAlbums(List<dynamic> data) {
  ParseResult result = ParseResult();
  data.forEach((json) => result.add(Album.fromJson(json), json['id']));

  return result;
}

class AlbumProvider with ChangeNotifier {
  ArtistProvider _artistProvider;
  late List<Album> _albums;
  late Map<int, Album> _index;

  AlbumProvider({required ArtistProvider artistProvider})
      : _artistProvider = artistProvider;

  List<Album> get albums => _albums;

  Future<void> init(List<dynamic> albumData) async {
    ParseResult result = await compute(parseAlbums, albumData);
    _albums = result.collection.cast();
    _index = result.index.cast();

    _albums.forEach((album) {
      album.artist = _artistProvider.byId(album.artistId);
    });
  }

  Album byId(int id) => _index[id]!;

  List<Album> byIds(List<int> ids) {
    List<Album> albums = [];

    ids.forEach((id) {
      if (_index.containsKey(id)) {
        albums.add(_index[id]!);
      }
    });

    return albums;
  }

  List<Album> mostPlayed({int limit = 15}) {
    List<Album> clone = List<Album>.from(_albums)
        .where((album) => album.isStandardAlbum)
        .toList()
          ..sort((a, b) => b.playCount.compareTo(a.playCount));

    return clone.take(limit).toList();
  }
}

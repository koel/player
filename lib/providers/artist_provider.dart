import 'package:app/models/models.dart';
import 'package:flutter/foundation.dart';

class ArtistProvider with ChangeNotifier {
  List<Artist> artists = [];
  Map<int, Artist> vault = {};

  Artist? byId(int id) => vault[id];

  List<Artist> byIds(List<int> ids) {
    List<Artist> artists = [];

    ids.forEach((id) {
      if (vault.containsKey(id)) {
        artists.add(vault[id]!);
      }
    });

    return artists;
  }

  List<Artist> syncWithVault(dynamic _artists) {
    if (!(_artists is List<Artist> || _artists is Artist)) {
      throw Exception(
        'Invalid type for artists. Must be List<Artist> or Artist.',
      );
    }

    if (_artists is Artist) {
      _artists = [_artists];
    }

    List<Artist> synced = (_artists as List<Artist>).map<Artist>((remote) {
      Artist? local = byId(remote.id);

      if (local == null) {
        artists.add(remote);
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

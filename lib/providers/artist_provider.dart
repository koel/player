import 'package:app/models/models.dart';
import 'package:app/utils/api_request.dart';
import 'package:flutter/foundation.dart';

class ArtistProvider with ChangeNotifier {
  List<Artist> artists = [];
  Map<int, Artist> _vault = {};
  int _page = 1;

  Artist? byId(int id) => _vault[id];

  List<Artist> byIds(List<int> ids) {
    List<Artist> artists = [];

    ids.forEach((id) {
      if (_vault.containsKey(id)) {
        artists.add(_vault[id]!);
      }
    });

    return artists;
  }

  Future<Artist> resolve(int id, {bool forceRefresh = false}) async {
    if (!_vault.containsKey(id) || forceRefresh) {
      _vault[id] = Artist.fromJson(await get('artists/$id'));
    }

    return _vault[id]!;
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
    var res = await get('artists?page=$_page');

    List<Artist> _artists = (res['data'] as List)
        .map<Artist>((artist) => Artist.fromJson(artist))
        .toList();

    List<Artist> synced = syncWithVault(_artists);
    artists = [...artists, ...synced].toSet().toList();

    _page = res['links']['next'] == null ? 1 : ++res['meta']['current_page'];

    notifyListeners();
  }
}

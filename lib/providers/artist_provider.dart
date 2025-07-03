import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/utils/api_request.dart';
import 'package:flutter/foundation.dart';

class ArtistProvider with ChangeNotifier, StreamSubscriber {
  var artists = <Artist>[];
  final _vault = <dynamic, Artist>{};
  var _page = 1;

  ArtistProvider() {
    subscribe(AuthProvider.userLoggedOutStream.listen((_) {
      artists.clear();
      _vault.clear();
      _page = 1;

      notifyListeners();
    }));
  }

  Artist? byId(dynamic id) => _vault[id];

  List<Artist> byIds(List<dynamic> ids) {
    final artists = <Artist>[];

    ids.forEach((id) {
      if (_vault.containsKey(id)) {
        artists.add(_vault[id]!);
      }
    });

    return artists;
  }

  Future<Artist> resolve(dynamic id, {bool forceRefresh = false}) async {
    if (!_vault.containsKey(id) || forceRefresh) {
      _vault[id] = Artist.fromJson(await get('artists/$id'));
    }

    return _vault[id]!;
  }

  List<Artist> syncWithVault(dynamic _artists) {
    assert(_artists is List<Artist> || _artists is Artist);

    if (_artists is Artist) {
      _artists = [_artists];
    }

    List<Artist> synced = (_artists as List<Artist>)
        .map<Artist>((remote) {
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
    final res = await get('artists?page=$_page');

    final _artists = (res['data'] as List)
        .map<Artist>((artist) => Artist.fromJson(artist))
        .toList();

    List<Artist> synced = syncWithVault(_artists);
    artists = [...artists, ...synced].toSet().toList();

    _page = res['links']['next'] == null ? 1 : ++res['meta']['current_page'];

    notifyListeners();
  }

  Future<void> refresh() {
    artists.clear();
    _page = 1;

    return paginate();
  }
}

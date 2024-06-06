import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/utils/api_request.dart';
import 'package:flutter/material.dart';
import 'providers.dart';

class RecentlyPlayedProvider with ChangeNotifier, StreamSubscriber {
  final SongProvider _songProvider;
  var _loaded = false;
  var songs = <Song>[];

  RecentlyPlayedProvider({required songProvider})
      : _songProvider = songProvider {
    subscribe(AuthProvider.userLoggedOutStream.listen((_) {
      songs.clear();
      _loaded = false;

      notifyListeners();
    }));
  }

  Future<List<Song>> fetch() async {
    final res = await get('songs/recently-played');
    final items = <Song>[];

    res.forEach((json) {
      if (json['type'] == 'songs') {
        items.add(Song.fromJson(json));
      }
    });

    songs = _songProvider.syncWithVault(items);
    _loaded = true;
    notifyListeners();
    return songs;
  }

  void add(Song song) {
    if (!_loaded) return;

    songs.remove(song);
    songs.insert(0, song);
    notifyListeners();
  }
}

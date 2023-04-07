import 'package:app/models/models.dart';
import 'package:app/utils/api_request.dart';
import 'package:flutter/material.dart';
import 'providers.dart';

class RecentlyPlayedProvider extends ChangeNotifier {
  final SongProvider _songProvider;
  var _loaded = false;
  var songs = <Song>[];

  RecentlyPlayedProvider({required songProvider})
      : _songProvider = songProvider;

  Future<List<Song>> fetch() async {
    final res = await get('songs/recently-played');
    final items = res.map<Song>((j) => Song.fromJson(j)).toList();
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

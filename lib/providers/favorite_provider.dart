import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/utils/api_request.dart';
import 'package:flutter/foundation.dart';

class FavoriteProvider with ChangeNotifier {
  final songs = <Song>[];
  late final SongProvider _songProvider;
  late final AppStateProvider _appState;

  FavoriteProvider({
    required SongProvider songProvider,
    required AppStateProvider appState,
  }) {
    _songProvider = songProvider;
    _appState = appState;
  }

  Future<List<Song>> fetch({bool forceRefresh = false}) async {
    if (forceRefresh) _appState.delete(['favorites']);

    if (_appState.has(['favorites'])) {
      songs
        ..clear()
        ..addAll(_appState.get(['favorites']));
    } else {
      final response = await get('songs/favorite');
      final _songs = response.map<Song>((j) => Song.fromJson(j)).toList();

      songs
        ..clear()
        ..addAll(_songProvider.syncWithVault(_songs));

      _appState.set(['favorites'], songs);
    }

    notifyListeners();

    return songs;
  }

  Future<void> unlike({required Song song}) async {
    song.liked = false;
    songs.remove(song);
    notifyListeners();

    await post('interaction/batch/unlike', data: {
      'songs': [song.id],
    });
  }

  Future<void> toggleOne({required Song song}) async {
    song.liked = !song.liked;

    if (song.liked) {
      songs.add(song);
    } else {
      songs.remove(song);
    }

    notifyListeners();

    await post('interaction/like', data: {'song': song.id});
  }
}

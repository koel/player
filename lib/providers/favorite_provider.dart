import 'package:app/app_state.dart';
import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/utils/api_request.dart';
import 'package:flutter/foundation.dart';

class FavoriteProvider with ChangeNotifier, StreamSubscriber {
  var songs = <Song>[];
  late final SongProvider _songProvider;

  FavoriteProvider({required SongProvider songProvider})
      : _songProvider = songProvider {
    subscribe(AuthProvider.userLoggedOutStream.listen((_) {
      songs.clear();
      notifyListeners();
    }));
  }

  Future<List<Song>> fetch({bool forceRefresh = false}) async {
    if (forceRefresh) AppState.delete(['favorites']);

    if (AppState.has(['favorites'])) {
      songs = AppState.get<List<Song>>(['favorites'])!;
    } else {
      final response = await get('songs/favorite');
      final _songs = response.map<Song>((j) => Song.fromJson(j)).toList();
      songs = _songProvider.syncWithVault(_songs);
      AppState.set(['favorites'], songs);
    }

    notifyListeners();

    return songs;
  }

  Future<void> unlike(Song song) async {
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

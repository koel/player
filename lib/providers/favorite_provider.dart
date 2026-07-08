import 'package:app/app_state.dart';
import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/utils/api_request.dart';
import 'package:flutter/foundation.dart';

class FavoriteProvider with ChangeNotifier, StreamSubscriber {
  var playables = <Playable>[];
  late final PlayableProvider _playableProvider;

  FavoriteProvider({required PlayableProvider playableProvider})
      : _playableProvider = playableProvider {
    subscribe(AuthProvider.userLoggedOutStream.listen((_) {
      playables.clear();
      notifyListeners();
    }));
  }

  Future<List<Playable>> fetch({bool forceRefresh = false}) async {
    if (forceRefresh) AppState.delete(['favorites']);

    if (AppState.has(['favorites'])) {
      playables = AppState.get<List<Playable>>(['favorites'])!;
    } else {
      final response = await get('songs/favorite');
      final _playables =
          response.map<Playable>((j) => Playable.fromJson(j)).toList();
      playables = _playableProvider.syncWithVault(_playables);
      AppState.set(['favorites'], playables);
    }

    notifyListeners();

    return playables;
  }

  void _setLiked(Playable playable, bool liked) {
    playable.liked = liked;

    if (liked) {
      playables.add(playable);
    } else {
      playables.remove(playable);
    }

    notifyListeners();
  }

  Future<void> unlike(Playable playable) async {
    _setLiked(playable, false);

    try {
      await post('interaction/batch/unlike', data: {
        'songs': [playable.id],
      });
    } catch (e) {
      _setLiked(playable, true);
      rethrow;
    }
  }

  Future<void> toggleOne({required Playable playable}) async {
    final liked = !playable.liked;
    _setLiked(playable, liked);

    try {
      await post('interaction/like', data: {'song': playable.id});
    } catch (e) {
      _setLiked(playable, !liked);
      rethrow;
    }
  }
}

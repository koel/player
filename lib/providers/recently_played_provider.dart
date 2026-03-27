import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/utils/api_request.dart';
import 'package:flutter/material.dart';

import 'providers.dart';

class RecentlyPlayedProvider with ChangeNotifier, StreamSubscriber {
  final PlayableProvider _playableProvider;
  var _loaded = false;
  var playables = <Playable>[];

  RecentlyPlayedProvider({required playableProvider})
      : _playableProvider = playableProvider {
    subscribe(AuthProvider.userLoggedOutStream.listen((_) {
      playables.clear();
      _loaded = false;

      notifyListeners();
    }));
  }

  Future<List<Playable>> fetch() async {
    final res = await get('songs/recently-played');
    final items = <Playable>[];

    res.forEach((json) => items.add(Playable.fromJson(json)));

    playables = _playableProvider.syncWithVault(items);
    _loaded = true;
    notifyListeners();
    return playables;
  }

  void seed(List<Playable> items) {
    // The API returns items sorted by most recently played.
    // If a song was added during playback (before seed is called),
    // re-insert it at the top since it's the most recent.
    final current = List<Playable>.from(playables);
    playables = List.from(items);

    for (final playable in current) {
      playables.remove(playable);
      playables.insert(0, playable);
    }

    notifyListeners();
  }

  void add(Playable playable) {
    playables.remove(playable);
    playables.insert(0, playable);
    notifyListeners();
  }
}

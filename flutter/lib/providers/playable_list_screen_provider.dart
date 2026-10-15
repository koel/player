import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/values/pagination_result.dart';
import 'package:flutter/foundation.dart';

class PlayableListScreenProvider with ChangeNotifier, StreamSubscriber {
  final PlayableProvider _playableProvider;
  final SearchProvider _searchProvider;

  List<Playable> playables = [];

  PlayableListScreenProvider({
    required playableProvider,
    required searchProvider,
  })  : _playableProvider = playableProvider,
        _searchProvider = searchProvider {
    subscribe(AuthProvider.userLoggedOutStream.listen((_) {
      playables.clear();
      notifyListeners();
    }));
  }

  Future<PaginationResult?> fetch({
    PlayablePaginationConfig? paginationConfig,
    String searchQuery = '',
  }) async {
    assert(paginationConfig != null || searchQuery.isNotEmpty);
    PaginationResult? result;

    if (searchQuery.isNotEmpty) {
      playables = await _searchProvider.searchPlayables(searchQuery);
    } else {
      result = await _playableProvider.paginate(paginationConfig!);
      playables = _playableProvider.playables;
    }

    notifyListeners();

    return result;
  }
}

import 'package:app/enums.dart';
import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/utils/api_request.dart';
import 'package:flutter/foundation.dart';

class GenreProvider with ChangeNotifier, StreamSubscriber {
  var genres = <Genre>[];
  final _vault = <String, Genre>{};
  var _sortField = 'name';
  var _sortOrder = SortOrder.asc;

  String get sortField => _sortField;
  SortOrder get sortOrder => _sortOrder;

  set sortField(String field) {
    if (field != _sortField) {
      _sortOrder = SortOrder.asc;
    }
    _sortField = field;
  }

  set sortOrder(SortOrder order) {
    _sortOrder = order;
  }

  GenreProvider() {
    subscribe(AuthProvider.userLoggedOutStream.listen((_) {
      genres.clear();
      _vault.clear();
      notifyListeners();
    }));
  }

  Genre? byId(String id) => _vault[id];

  Future<void> fetch() async {
    final res = await get('genres');
    final items = (res as List)
        .map<Genre>((json) => Genre.fromJson(json))
        .toList();

    for (final genre in items) {
      final local = _vault[genre.id];
      if (local != null) {
        local.merge(genre);
      } else {
        _vault[genre.id] = genre;
      }
    }

    genres = items;
    notifyListeners();
  }

  Future<void> refresh() {
    genres.clear();
    return fetch();
  }
}

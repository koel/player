import 'package:app/enums.dart';
import 'package:app/models/models.dart';
import 'package:app/values/values.dart';

extension PlayableListExtension on List<Playable> {
  List<Playable> $filter(String keywords) {
    if (keywords.isEmpty) {
      return this;
    }

    keywords = keywords.toLowerCase();

    return where((playable) => playable.matchKeywords(keywords)).toList();
  }

  List<Playable> $sort(PlayableSortConfig config) {
    return this
      ..sort((a, b) => config.order == SortOrder.asc
          ? a.valueToCompare(config).compareTo(b.valueToCompare(config))
          : b.valueToCompare(config).compareTo(a.valueToCompare(config)));
  }
}

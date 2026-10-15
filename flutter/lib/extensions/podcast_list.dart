import 'package:app/enums.dart';
import 'package:app/models/models.dart';
import 'package:app/ui/screens/podcasts.dart';

extension PodcastListExtension on List<Podcast> {
  List<Podcast> $sort(PodcastSortConfig config) {
    return this
      ..sort(
        (a, b) => config.order == SortOrder.asc
            ? a.compare(b, config.field)
            : b.compare(a, config.field),
      );
  }
}

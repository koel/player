enum SortOrder { asc, desc }

enum AppMode { online, offline }

extension SortOrderExtension on SortOrder {
  String get value => toString().split('.').last;
}

enum ThumbnailSize { xs, sm, md, lg, xl }

enum PodcastSortField {
  lastPlayedAt,
  subscribedAt,
  title,
  author,
}

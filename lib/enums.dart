enum SortOrder { asc, desc }

enum AppMode { online, offline }

extension SortOrderExtension on SortOrder {
  String get value => toString().split('.').last;
}

enum ThumbnailSize { sm, md, lg, xl }

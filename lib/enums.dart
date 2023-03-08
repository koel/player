enum SortOrder {
  asc,
  desc,
}

extension SortOrderExtension on SortOrder {
  String get value => toString().split('.').last;
}

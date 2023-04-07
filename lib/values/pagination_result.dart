class PaginationResult<T> {
  List<T> items;
  int? nextPage;

  PaginationResult({
    required this.items,
    this.nextPage,
  });
}

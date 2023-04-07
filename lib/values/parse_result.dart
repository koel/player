class ParseResult {
  late List _collection;
  late Map _index;

  ParseResult() {
    this._collection = [];
    this._index = new Map();
  }

  add(dynamic item, dynamic identifier) {
    this._collection.add(item);
    this._index[identifier] = item;
  }

  List get collection => _collection;
  Map get index => _index;
}

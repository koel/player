import 'dart:convert';

class AppStateProvider {
  final _state = <String, dynamic>{};

  String _normalizeKey(Object key) => jsonEncode(key);

  T? get<T>(Object key) => _state[_normalizeKey(key)];

  T set<T>(Object key, T value) {
    _state[_normalizeKey(key)] = value;
    return value;
  }

  bool has(Object key) => _state.containsKey(_normalizeKey(key));

  void delete(Object key) => _state.remove(_normalizeKey(key));
}

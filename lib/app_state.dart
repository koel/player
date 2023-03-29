import 'dart:convert';

class AppState {
  final _state = <String, dynamic>{};

  String _normalizeKey(Object key) => jsonEncode(key);

  T? get<T>(Object key, [T? defaultValue]) {
    if (!has(key)) return defaultValue;
    if (_state[_normalizeKey(key)] == null) return defaultValue;

    return _state[_normalizeKey(key)];
  }

  T set<T>(Object key, T value) {
    _state[_normalizeKey(key)] = value;
    return value;
  }

  bool has(Object key) => _state.containsKey(_normalizeKey(key));

  void delete(Object key) => _state.remove(_normalizeKey(key));
}

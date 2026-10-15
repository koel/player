import 'dart:convert';

class AppState {
  static var _state = <String, dynamic>{};

  static String _normalizeKey(Object key) => jsonEncode(key);

  static T? get<T>(Object key, [T? defaultValue]) {
    if (!has(key)) return defaultValue;
    if (_state[_normalizeKey(key)] == null) return defaultValue;

    return _state[_normalizeKey(key)];
  }

  static T set<T>(Object key, T value) {
    _state[_normalizeKey(key)] = value;
    return value;
  }

  static bool has(Object key) => _state.containsKey(_normalizeKey(key));

  static void delete(Object key) => _state.remove(_normalizeKey(key));

  static void clear() => _state.clear();
}

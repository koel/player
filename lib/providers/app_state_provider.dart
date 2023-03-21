import 'dart:convert';

class AppStateProvider {
  Map<String, dynamic> _state = {};

  String _normalizeKey(Object key) => jsonEncode(key);

  T? get<T>(Object key) => _state[_normalizeKey(key)];

  set(Object key, dynamic value) => _state[_normalizeKey(key)] = value;

  bool has(Object key) => _state.containsKey(_normalizeKey(key));

  void delete(Object key) => _state.remove(_normalizeKey(key));
}

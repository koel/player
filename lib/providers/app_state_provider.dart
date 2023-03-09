class AppStateProvider {
  Map<String, dynamic> _state = {};

  get<T>(String key) => _state[key] as T;

  set(String key, dynamic value) => _state[key] = value;

  bool has(String key) => _state.containsKey(key);

  bool doesNotHave(String key) => !has(key);
}

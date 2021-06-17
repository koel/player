abstract class RequiresInitialization {
  bool initialized = false;

  void ensureInitialization() {
    if (!initialized) {
      throw Exception("$runtimeType must be initialized first");
    }
  }
}

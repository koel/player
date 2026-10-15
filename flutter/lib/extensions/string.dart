extension StringExtension on String {
  String pluralize(int count, {String suffix = 's'}) {
    assert(count >= 0);
    return count == 1 ? this : this + suffix;
  }
}

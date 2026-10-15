import 'package:app/ui/screens/home.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String idOf(String id) => id;

  test('keeps the default order when no preference is saved', () {
    final ordered = orderByHomeBlocksPreference(
      ['a', 'b', 'c'],
      idOf,
      const [],
    );

    expect(ordered, ['a', 'b', 'c']);
  });

  test('moves saved blocks to the front in the saved order', () {
    final ordered = orderByHomeBlocksPreference(
      ['a', 'b', 'c', 'd'],
      idOf,
      ['c', 'a'],
    );

    // c, a first (saved order), then the rest keep their default order.
    expect(ordered, ['c', 'a', 'b', 'd']);
  });

  test('ignores saved ids that have no matching block', () {
    final ordered = orderByHomeBlocksPreference(
      ['a', 'b'],
      idOf,
      ['x', 'b', 'y'],
    );

    expect(ordered, ['b', 'a']);
  });

  test('preserves the default order of blocks absent from the preference', () {
    final ordered = orderByHomeBlocksPreference(
      ['a', 'b', 'c', 'd', 'e'],
      idOf,
      ['e'],
    );

    expect(ordered, ['e', 'a', 'b', 'c', 'd']);
  });
}

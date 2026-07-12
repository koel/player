import 'package:app/enums.dart';
import 'package:app/extensions/extensions.dart';
import 'package:app/models/models.dart';
import 'package:app/values/values.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Song a, b, c;

  setUp(() {
    a = Song.fake(title: 'A');
    b = Song.fake(title: 'B');
    c = Song.fake(title: 'C');
  });

  // Deliberately not alphabetical — mimics a playlist's custom order.
  List<Playable> customOrder() => <Playable>[c, a, b];

  PlayableSortConfig config(String field, SortOrder order) =>
      PlayableSortConfig(field: field, order: order);

  group('\$sort', () {
    test('position keeps the server-provided order', () {
      final sorted = customOrder().$sort(config('position', SortOrder.asc));
      expect(sorted, [c, a, b]);
    });

    test('position descending reverses the server-provided order', () {
      final sorted = customOrder().$sort(config('position', SortOrder.desc));
      expect(sorted, [b, a, c]);
    });

    test('other fields still sort', () {
      final sorted = customOrder().$sort(config('title', SortOrder.asc));
      expect(sorted.map((playable) => (playable as Song).title), ['A', 'B', 'C']);
    });

    test('does not mutate the original list', () {
      final original = customOrder();
      original.$sort(config('title', SortOrder.asc));
      expect(original, [c, a, b]);
    });
  });
}

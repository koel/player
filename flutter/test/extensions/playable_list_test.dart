import 'package:app/enums.dart';
import 'package:app/extensions/extensions.dart';
import 'package:app/models/models.dart';
import 'package:app/values/values.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Song songA, songB, songC;

  setUp(() {
    songA = Song.fake(title: 'A');
    songB = Song.fake(title: 'B');
    songC = Song.fake(title: 'C');
  });

  // Deliberately not alphabetical — mimics a playlist's custom order.
  List<Playable> customOrder() => <Playable>[songC, songA, songB];

  PlayableSortConfig config(String field, SortOrder order) =>
      PlayableSortConfig(field: field, order: order);

  group('\$sort', () {
    test('position keeps the server-provided order', () {
      final sorted = customOrder().$sort(config('position', SortOrder.asc));
      expect(sorted, [songC, songA, songB]);
    });

    test('position descending reverses the server-provided order', () {
      final sorted = customOrder().$sort(config('position', SortOrder.desc));
      expect(sorted, [songB, songA, songC]);
    });

    test('other fields still sort', () {
      final sorted = customOrder().$sort(config('title', SortOrder.asc));
      expect(sorted.map((playable) => (playable as Song).title), ['A', 'B', 'C']);
    });

    test('does not mutate the original list', () {
      final original = customOrder();
      original.$sort(config('title', SortOrder.asc));
      original.$sort(config('position', SortOrder.asc));
      original.$sort(config('position', SortOrder.desc));
      expect(original, [songC, songA, songB]);
    });
  });
}

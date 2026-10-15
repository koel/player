import 'package:app/models/models.dart';
import 'package:app/providers/search_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SearchResult', () {
    test('has empty defaults', () {
      final result = SearchResult();
      expect(result.playables, isEmpty);
      expect(result.artists, isEmpty);
      expect(result.albums, isEmpty);
      expect(result.podcasts, isEmpty);
      expect(result.radioStations, isEmpty);
    });

    test('accepts radio stations', () {
      final stations = [
        RadioStation.fake(name: 'Jazz FM'),
        RadioStation.fake(name: 'Rock Radio'),
      ];

      final result = SearchResult(radioStations: stations);
      expect(result.radioStations, hasLength(2));
      expect(result.radioStations[0].name, 'Jazz FM');
      expect(result.radioStations[1].name, 'Rock Radio');
    });

    test('accepts all result types together', () {
      final stations = [RadioStation.fake(name: 'Jazz FM')];

      final result = SearchResult(
        playables: [],
        artists: [],
        albums: [],
        podcasts: [],
        radioStations: stations,
      );

      expect(result.radioStations, hasLength(1));
    });
  });
}

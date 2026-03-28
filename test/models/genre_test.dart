import 'package:app/models/genre.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Genre.fromJson', () {
    test('parses all fields', () {
      final json = {
        'id': 'rock',
        'name': 'Rock',
        'song_count': 42,
        'length': 12345,
      };

      final genre = Genre.fromJson(json);
      expect(genre.id, 'rock');
      expect(genre.name, 'Rock');
      expect(genre.songCount, 42);
      expect(genre.length, 12345);
    });

    test('handles missing fields', () {
      final genre = Genre.fromJson({'id': 'x', 'name': 'X'});
      expect(genre.songCount, 0);
      expect(genre.length, 0);
    });
  });

  group('formattedLength', () {
    test('formats hours and minutes', () {
      final genre = Genre.fake(length: 7260); // 2h 1m
      expect(genre.formattedLength, '2h 1m');
    });

    test('formats minutes only', () {
      final genre = Genre.fake(length: 300); // 5m
      expect(genre.formattedLength, '5m');
    });
  });

  group('merge', () {
    test('updates fields from remote', () {
      final local = Genre.fake(name: 'Old', songCount: 1);
      final remote = Genre.fake(name: 'New', songCount: 5);

      local.merge(remote);
      expect(local.name, 'New');
      expect(local.songCount, 5);
    });
  });

  group('equality', () {
    test('genres with same id are equal', () {
      final a = Genre.fake(id: 'rock');
      final b = Genre.fake(id: 'rock');
      expect(a, equals(b));
    });

    test('genres with different ids are not equal', () {
      final a = Genre.fake(id: 'rock');
      final b = Genre.fake(id: 'pop');
      expect(a, isNot(equals(b)));
    });
  });
}

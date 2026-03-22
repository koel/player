import 'package:app/models/song.dart';
import 'package:app/models/playable.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Playable.fromJson', () {
    test('creates a Song when type is not episodes', () {
      final json = {
        'id': 'song-1',
        'title': 'Test Song',
        'lyrics': '',
        'length': 200,
        'created_at': '2023-01-01T00:00:00.000Z',
        'artist_id': 'a1',
        'artist_name': 'Artist',
        'album_id': 'b1',
        'album_name': 'Album',
        'album_cover': null,
        'album_artist_id': 'a1',
        'album_artist_name': 'Artist',
      };

      final playable = Playable.fromJson(json);
      expect(playable, isA<Song>());
      expect(playable.title, 'Test Song');
    });

    test('creates a Song when type is "songs"', () {
      final json = {
        'type': 'songs',
        'id': 'song-2',
        'title': 'Typed Song',
        'lyrics': '',
        'length': 180,
        'created_at': '2023-01-01T00:00:00.000Z',
        'artist_id': 'a1',
        'artist_name': 'Artist',
        'album_id': 'b1',
        'album_name': 'Album',
        'album_cover': null,
        'album_artist_id': 'a1',
        'album_artist_name': 'Artist',
      };

      final playable = Playable.fromJson(json);
      expect(playable, isA<Song>());
    });
  });

  group('Playable.tryFromJson', () {
    test('returns null for invalid JSON', () {
      final result = Playable.tryFromJson({'invalid': 'data'});
      expect(result, isNull);
    });

    test('returns Playable for valid JSON', () {
      final json = {
        'id': 'song-1',
        'title': 'Valid',
        'lyrics': '',
        'length': 100,
        'created_at': '2023-01-01T00:00:00.000Z',
        'artist_id': 'a1',
        'artist_name': 'Artist',
        'album_id': 'b1',
        'album_name': 'Album',
        'album_cover': null,
        'album_artist_id': 'a1',
        'album_artist_name': 'Artist',
      };

      final result = Playable.tryFromJson(json);
      expect(result, isNotNull);
      expect(result, isA<Song>());
    });
  });

  group('Playable equality', () {
    test('two playables with same id are equal', () {
      final a = Song.fake(id: 'same-id');
      final b = Song.fake(id: 'same-id');
      expect(a, equals(b));
    });

    test('two playables with different ids are not equal', () {
      final a = Song.fake(id: 'id-1');
      final b = Song.fake(id: 'id-2');
      expect(a, isNot(equals(b)));
    });

    test('hashCode is based on id', () {
      final a = Song.fake(id: 'same-id');
      final b = Song.fake(id: 'same-id');
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('Playable.cacheKey', () {
    test('prefixes id with CACHE_', () {
      final song = Song.fake(id: 'my-song-id');
      expect(song.cacheKey, 'CACHE_my-song-id');
    });
  });
}

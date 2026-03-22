import 'package:app/enums.dart';
import 'package:app/models/artist.dart';
import 'package:app/models/album.dart';
import 'package:app/models/song.dart';
import 'package:app/values/playable_sort_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Song.fromJson', () {
    test('parses all fields from JSON', () {
      final json = {
        'id': 'abc-123',
        'title': 'Test Song',
        'lyrics': 'la la la',
        'length': 240,
        'track': 5,
        'disc': 2,
        'year': '2023',
        'genre': 'Rock',
        'liked': true,
        'created_at': '2023-06-15T10:30:00.000Z',
        'artist_id': 'artist-1',
        'artist_name': 'Test Artist',
        'album_id': 'album-1',
        'album_name': 'Test Album',
        'album_cover': 'https://example.com/cover.jpg',
        'album_artist_id': 'artist-1',
        'album_artist_name': 'Test Artist',
      };

      final song = Song.fromJson(json);

      expect(song.id, 'abc-123');
      expect(song.title, 'Test Song');
      expect(song.lyrics, 'la la la');
      expect(song.length, 240);
      expect(song.track, 5);
      expect(song.disc, 2);
      expect(song.year, 2023);
      expect(song.genre, 'Rock');
      expect(song.liked, isTrue);
      expect(song.artistName, 'Test Artist');
      expect(song.albumName, 'Test Album');
      expect(song.albumCoverUrl, 'https://example.com/cover.jpg');
    });

    test('handles null optional fields', () {
      final json = {
        'id': 'abc-123',
        'title': 'Minimal Song',
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

      final song = Song.fromJson(json);

      expect(song.lyrics, '');
      expect(song.track, 0);
      expect(song.disc, 1);
      expect(song.year, isNull);
      expect(song.genre, '');
      expect(song.liked, isFalse);
      expect(song.albumCoverUrl, isNull);
    });
  });

  group('Song.toJson', () {
    test('round-trips through JSON', () {
      final original = Song.fake(
        title: 'Round Trip',
        genre: 'Jazz',
        track: 3,
        disc: 1,
        year: 2020,
      );

      final json = original.toJson();
      final restored = Song.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.title, 'Round Trip');
      expect(restored.genre, 'Jazz');
      expect(restored.track, original.track);
      expect(restored.year, 2020);
      expect(json['type'], 'songs');
    });
  });

  group('Song.matchKeywords', () {
    late Song song;

    setUp(() {
      song = Song.fake(
        title: 'Bohemian Rhapsody',
        artist: Artist.fake(name: 'Queen'),
        album: Album.fake(name: 'A Night at the Opera'),
      );
    });

    test('matches by title', () {
      expect(song.matchKeywords('bohemian'), isTrue);
      expect(song.matchKeywords('rhapsody'), isTrue);
    });

    test('matches by artist name', () {
      expect(song.matchKeywords('queen'), isTrue);
    });

    test('matches by album name', () {
      expect(song.matchKeywords('opera'), isTrue);
    });

    test('requires lowercase keywords (implementation detail)', () {
      // matchKeywords lowercases stored values but not the input
      expect(song.matchKeywords('BOHEMIAN'), isFalse);
      expect(song.matchKeywords('bohemian'), isTrue);
    });

    test('returns false for non-matching keywords', () {
      expect(song.matchKeywords('banana'), isFalse);
    });
  });

  group('Song.valueToCompare', () {
    late Song song;

    setUp(() {
      song = Song.fake(
        title: 'Test Title',
        artist: Artist.fake(name: 'Test Artist'),
        album: Album.fake(name: 'Test Album'),
      );
    });

    test('returns title for title sort', () {
      final config =
          PlayableSortConfig(field: 'title', order: SortOrder.asc);
      expect(song.valueToCompare(config), 'Test Title');
    });

    test('returns composite for album_name sort', () {
      final config =
          PlayableSortConfig(field: 'album_name', order: SortOrder.asc);
      final value = song.valueToCompare(config) as String;
      expect(value, contains('Test Album'));
    });

    test('returns composite for artist_name sort', () {
      final config =
          PlayableSortConfig(field: 'artist_name', order: SortOrder.asc);
      final value = song.valueToCompare(config) as String;
      expect(value, contains('Test Artist'));
    });

    test('returns track for track sort', () {
      final config =
          PlayableSortConfig(field: 'track', order: SortOrder.asc);
      expect(song.valueToCompare(config), song.track);
    });

    test('returns createdAt for created_at sort', () {
      final config =
          PlayableSortConfig(field: 'created_at', order: SortOrder.asc);
      expect(song.valueToCompare(config), song.createdAt);
    });

    test('returns empty string for unknown field', () {
      final config =
          PlayableSortConfig(field: 'unknown', order: SortOrder.asc);
      expect(song.valueToCompare(config), '');
    });
  });

  group('Song.merge', () {
    test('merges fields from another song', () {
      final original = Song.fake(title: 'Original', genre: 'Rock');
      final updated = Song.fake(
        id: original.id,
        title: 'Updated',
        genre: 'Pop',
      );

      original.merge(updated);

      expect(original.title, 'Updated');
      expect(original.genre, 'Pop');
    });
  });

  group('Song.fake', () {
    test('generates a valid song', () {
      final song = Song.fake();

      expect(song.id, isNotEmpty);
      expect(song.title, isNotEmpty);
      expect(song.artistName, isNotEmpty);
      expect(song.albumName, isNotEmpty);
    });

    test('respects custom parameters', () {
      final artist = Artist.fake(name: 'Custom Artist');
      final song = Song.fake(
        title: 'Custom Title',
        artist: artist,
      );

      expect(song.title, 'Custom Title');
      expect(song.artistName, 'Custom Artist');
    });
  });

  group('Song.fakeMany', () {
    test('generates the correct count', () {
      final songs = Song.fakeMany(5);
      expect(songs.length, 5);
    });

    test('generates unique ids', () {
      final songs = Song.fakeMany(3);
      final ids = songs.map((s) => s.id).toSet();
      expect(ids.length, 3);
    });
  });
}

import 'package:app/models/album.dart';
import 'package:app/models/artist.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Album.fromJson', () {
    test('parses all fields', () {
      final json = {
        'id': 10,
        'name': 'Abbey Road',
        'cover': 'https://example.com/cover.jpg',
        'artist_id': 1,
        'artist_name': 'The Beatles',
      };

      final album = Album.fromJson(json);

      expect(album.id, 10);
      expect(album.name, 'Abbey Road');
      expect(album.cover, 'https://example.com/cover.jpg');
      expect(album.artistId, 1);
      expect(album.artistName, 'The Beatles');
    });

    test('handles null cover', () {
      final json = {
        'id': 1,
        'name': 'No Cover',
        'cover': null,
        'artist_id': 1,
        'artist_name': 'Artist',
      };

      final album = Album.fromJson(json);
      expect(album.cover, isNull);
    });
  });

  group('Album boolean properties', () {
    test('isUnknownAlbum', () {
      expect(Album.fake(name: 'Unknown Album').isUnknownAlbum, isTrue);
      expect(Album.fake(name: 'Real Album').isUnknownAlbum, isFalse);
    });

    test('isStandardAlbum', () {
      expect(Album.fake(name: 'Real Album').isStandardAlbum, isTrue);
      expect(Album.fake(name: 'Unknown Album').isStandardAlbum, isFalse);
    });
  });

  group('Album.merge', () {
    test('merges fields from remote', () {
      final local = Album.fake(name: 'Old Name');
      final remote = Album.fake(name: 'New Name');

      local.merge(remote);

      expect(local.name, 'New Name');
      expect(local.cover, remote.cover);
      expect(local.artistName, remote.artistName);
    });
  });

  group('Album.fake', () {
    test('generates a valid album', () {
      final album = Album.fake();
      expect(album.id, isNotNull);
      expect(album.name, isNotEmpty);
    });

    test('uses provided artist', () {
      final artist = Artist.fake(name: 'Custom Artist');
      final album = Album.fake(artist: artist);
      expect(album.artistName, 'Custom Artist');
      expect(album.artistId, artist.id);
    });
  });
}

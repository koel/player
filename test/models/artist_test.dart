import 'package:app/models/artist.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Artist.fromJson', () {
    test('parses all fields', () {
      final json = {
        'id': 42,
        'name': 'Led Zeppelin',
        'image': 'https://example.com/artist.jpg',
      };

      final artist = Artist.fromJson(json);

      expect(artist.id, 42);
      expect(artist.name, 'Led Zeppelin');
      expect(artist.imageUrl, 'https://example.com/artist.jpg');
    });

    test('handles null image', () {
      final json = {
        'id': 1,
        'name': 'Unknown',
        'image': null,
      };

      final artist = Artist.fromJson(json);
      expect(artist.imageUrl, isNull);
    });

    test('parses canEdit from permissions', () {
      final json = {
        'id': 1,
        'name': 'Perm',
        'image': null,
        'permissions': {'edit': true},
      };

      expect(Artist.fromJson(json).canEdit, isTrue);
    });

    test('defaults canEdit to false when permissions is absent', () {
      final json = {
        'id': 1,
        'name': 'Old Server',
        'image': null,
      };

      expect(Artist.fromJson(json).canEdit, isFalse);
    });

    test('defaults canEdit to false when permissions.edit is non-bool', () {
      final json = {
        'id': 1,
        'name': 'Partial',
        'image': null,
        'permissions': {'edit': null},
      };

      expect(Artist.fromJson(json).canEdit, isFalse);
    });
  });

  group('Artist boolean properties', () {
    test('isUnknownArtist', () {
      expect(Artist.fake(name: 'Unknown Artist').isUnknownArtist, isTrue);
      expect(Artist.fake(name: 'Queen').isUnknownArtist, isFalse);
    });

    test('isVariousArtists', () {
      expect(Artist.fake(name: 'Various Artists').isVariousArtists, isTrue);
      expect(Artist.fake(name: 'Queen').isVariousArtists, isFalse);
    });

    test('isStandardArtist', () {
      expect(Artist.fake(name: 'Queen').isStandardArtist, isTrue);
      expect(Artist.fake(name: 'Unknown Artist').isStandardArtist, isFalse);
      expect(Artist.fake(name: 'Various Artists').isStandardArtist, isFalse);
    });
  });

  group('Artist.merge', () {
    test('merges fields from remote', () {
      final local = Artist.fake(name: 'Old Name');
      final remote = Artist.fake(name: 'New Name');

      local.merge(remote);

      expect(local.name, 'New Name');
      expect(local.imageUrl, remote.imageUrl);
    });

    test('merges canEdit from remote', () {
      final local = Artist.fake(canEdit: false);
      final remote = Artist.fake(canEdit: true);

      local.merge(remote);
      expect(local.canEdit, isTrue);
    });
  });

  group('Artist.fake', () {
    test('generates a valid artist', () {
      final artist = Artist.fake();
      expect(artist.id, isNotNull);
      expect(artist.name, isNotEmpty);
    });

    test('respects custom parameters', () {
      final artist = Artist.fake(name: 'Custom');
      expect(artist.name, 'Custom');
    });
  });
}

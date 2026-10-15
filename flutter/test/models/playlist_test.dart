import 'package:app/models/playlist.dart';
import 'package:app/models/song.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Playlist.fromJson', () {
    test('parses all fields', () {
      final json = {
        'id': 'playlist-1',
        'name': 'My Playlist',
        'is_smart': false,
      };

      final playlist = Playlist.fromJson(json);

      expect(playlist.id, 'playlist-1');
      expect(playlist.name, 'My Playlist');
      expect(playlist.isSmart, isFalse);
    });

    test('parses smart playlist', () {
      final json = {
        'id': 'smart-1',
        'name': 'Top Rated',
        'is_smart': true,
      };

      final playlist = Playlist.fromJson(json);
      expect(playlist.isSmart, isTrue);
    });

    test('parses cover', () {
      final json = {
        'id': 'playlist-c',
        'name': 'With Cover',
        'is_smart': false,
        'cover': 'https://example.com/cover.jpg',
      };

      final playlist = Playlist.fromJson(json);
      expect(playlist.cover, 'https://example.com/cover.jpg');
      expect(playlist.hasCover, isTrue);
    });

    test('hasCover is false when cover is null', () {
      final playlist = Playlist.fake();
      expect(playlist.hasCover, isFalse);
    });

    test('parses folder_id', () {
      final json = {
        'id': 'playlist-2',
        'name': 'In Folder',
        'is_smart': false,
        'folder_id': 'folder-uuid-1',
      };

      final playlist = Playlist.fromJson(json);
      expect(playlist.folderId, 'folder-uuid-1');
    });

    test('folder_id is null when not in a folder', () {
      final json = {
        'id': 'playlist-3',
        'name': 'Root Level',
        'is_smart': false,
        'folder_id': null,
      };

      final playlist = Playlist.fromJson(json);
      expect(playlist.folderId, isNull);
    });

    test('parses canEdit and canDelete from permissions', () {
      final json = {
        'id': 'playlist-perm',
        'name': 'Perm',
        'is_smart': false,
        'permissions': {'edit': true, 'delete': true},
      };

      final playlist = Playlist.fromJson(json);
      expect(playlist.canEdit, isTrue);
      expect(playlist.canDelete, isTrue);
    });

    test('honors per-action permission flags independently', () {
      final json = {
        'id': 'playlist-perm-mixed',
        'name': 'Mixed',
        'is_smart': false,
        'permissions': {'edit': true, 'delete': false},
      };

      final playlist = Playlist.fromJson(json);
      expect(playlist.canEdit, isTrue);
      expect(playlist.canDelete, isFalse);
    });

    test('defaults canEdit/canDelete to false when permissions is absent',
        () {
      // Older koel (< 9.2.0) doesn't include the permissions key. The
      // client should still parse the resource and treat both actions
      // as not permitted so the UI hides them.
      final json = {
        'id': 'playlist-old',
        'name': 'Old Server',
        'is_smart': false,
      };

      final playlist = Playlist.fromJson(json);
      expect(playlist.canEdit, isFalse);
      expect(playlist.canDelete, isFalse);
    });

    test('defaults to false when permissions keys are missing or non-bool',
        () {
      final json = {
        'id': 'playlist-partial',
        'name': 'Partial',
        'is_smart': false,
        'permissions': {'edit': null},
      };

      final playlist = Playlist.fromJson(json);
      expect(playlist.canEdit, isFalse);
      expect(playlist.canDelete, isFalse);
    });
  });

  group('Playlist properties', () {
    test('isEmpty when no playables', () {
      final playlist = Playlist.fake();
      expect(playlist.isEmpty, isTrue);
    });

    test('not empty when has playables', () {
      final playlist = Playlist.fake();
      playlist.playables = Song.fakeMany(3);
      expect(playlist.isEmpty, isFalse);
    });

    test('isStandard for non-smart playlist', () {
      final playlist = Playlist.fake(isSmart: false);
      expect(playlist.isStandard, isTrue);
    });

    test('isStandard is false for smart playlist', () {
      final playlist = Playlist.fake(isSmart: true);
      expect(playlist.isStandard, isFalse);
    });
  });

  group('Playlist.fake', () {
    test('generates a valid playlist', () {
      final playlist = Playlist.fake();
      expect(playlist.id, isNotNull);
      expect(playlist.name, isNotEmpty);
    });

    test('respects custom parameters', () {
      final playlist = Playlist.fake(name: 'Custom', isSmart: true);
      expect(playlist.name, 'Custom');
      expect(playlist.isSmart, isTrue);
    });
  });
}

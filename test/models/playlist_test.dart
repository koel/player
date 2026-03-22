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

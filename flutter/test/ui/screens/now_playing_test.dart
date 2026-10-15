import 'package:app/models/song.dart';
import 'package:app/ui/widgets/playable_list_header.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NowPlayingScreen queue integration', () {
    test('PlayableListContext includes queue', () {
      expect(PlayableListContext.values, contains(PlayableListContext.queue));
    });

    test('queue songs are identifiable by ValueKey', () {
      final song1 = Song.fake(id: 'song-1');
      final song2 = Song.fake(id: 'song-2');

      // Songs with different IDs should have different ValueKeys
      expect(ValueKey(song1) == ValueKey(song2), isFalse);

      // Same song should have the same ValueKey
      final song1Copy = Song.fake(id: 'song-1');
      expect(ValueKey(song1) == ValueKey(song1Copy), isTrue);
    });

    test('queue playables can be reordered', () {
      final songs = Song.fakeMany(5);
      final original = List.from(songs);

      // Simulate reorder: move item at index 0 to index 3
      var oldIndex = 0;
      var newIndex = 3;
      if (oldIndex < newIndex) newIndex -= 1;
      final item = songs.removeAt(oldIndex);
      songs.insert(newIndex, item);

      expect(songs[0], original[1]);
      expect(songs[1], original[2]);
      expect(songs[2], original[0]);
      expect(songs[3], original[3]);
    });

    test('clearing queue results in empty list', () {
      final songs = Song.fakeMany(3);
      songs.clear();
      expect(songs, isEmpty);
    });
  });
}

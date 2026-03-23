import 'package:app/models/song.dart';
import 'package:app/providers/recently_played_provider.dart';
import 'package:app/providers/playable_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'recently_played_provider_test.mocks.dart';

@GenerateMocks([PlayableProvider])
void main() {
  late RecentlyPlayedProvider provider;
  late MockPlayableProvider mockPlayableProvider;

  setUp(() {
    mockPlayableProvider = MockPlayableProvider();
    provider = RecentlyPlayedProvider(playableProvider: mockPlayableProvider);
  });

  group('seed', () {
    test('populates playables when list is empty', () {
      final songs = Song.fakeMany(3);
      provider.seed(songs);
      expect(provider.playables.length, 3);
    });

    test('does not overwrite existing playables', () {
      final existing = Song.fake(title: 'Existing');
      provider.playables = [existing];

      provider.seed(Song.fakeMany(5));
      expect(provider.playables.length, 1);
      expect(provider.playables.first, existing);
    });
  });

  group('add', () {
    test('inserts playable at the beginning', () {
      final songs = Song.fakeMany(3);
      provider.seed(songs);

      final newSong = Song.fake(title: 'New Song');
      provider.add(newSong);

      expect(provider.playables.first, newSong);
      expect(provider.playables.length, 4);
    });

    test('moves existing playable to the beginning', () {
      final songs = Song.fakeMany(3);
      provider.seed(songs);
      final lastSong = songs.last;

      provider.add(lastSong);

      expect(provider.playables.first, lastSong);
      expect(provider.playables.length, 3);
    });

    test('works even when list is empty', () {
      final song = Song.fake();
      provider.add(song);

      expect(provider.playables.length, 1);
      expect(provider.playables.first, song);
    });
  });
}

import 'package:app/models/song.dart';
import 'package:app/providers/download_provider.dart';
import 'package:app/providers/favorite_provider.dart';
import 'package:app/providers/playable_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../helpers/api_test_setup.dart';
import 'favorite_provider_test.mocks.dart';

@GenerateMocks([PlayableProvider, DownloadProvider])
void main() {
  late MockPlayableProvider playableProviderMock;
  late MockDownloadProvider downloadProviderMock;
  late FavoriteProvider provider;
  late CapturingClient client;

  setUpAll(() async => await initApiTestEnvironment());

  setUp(() {
    playableProviderMock = MockPlayableProvider();
    downloadProviderMock = MockDownloadProvider();
    provider = FavoriteProvider(
      playableProvider: playableProviderMock,
      downloadProvider: downloadProviderMock,
    );
    client = CapturingClient();
    client.install();
    setUpApiTest();
  });

  tearDown(tearDownApiTest);

  test('toggleOne likes a song and adds it to the list', () async {
    client.willReturn(json: {});
    final song = Song.fake(liked: false);

    await provider.toggleOne(playable: song);

    expect(song.liked, isTrue);
    expect(provider.playables, contains(song));
  });

  test('toggleOne rolls back the like when the request fails', () async {
    client.willReturnRaw(status: 500, body: 'nope');
    final song = Song.fake(liked: false);

    await expectLater(
      provider.toggleOne(playable: song),
      throwsA(anything),
    );

    expect(song.liked, isFalse);
    expect(provider.playables, isNot(contains(song)));
  });

  test('toggleOne rolls back an unlike when the request fails', () async {
    client.willReturnRaw(status: 500, body: 'nope');
    final song = Song.fake(liked: true);
    provider.playables.add(song);

    await expectLater(
      provider.toggleOne(playable: song),
      throwsA(anything),
    );

    expect(song.liked, isTrue);
    expect(provider.playables, contains(song));
  });

  test('unlike rolls back when the request fails', () async {
    client.willReturnRaw(status: 500, body: 'nope');
    final song = Song.fake(liked: true);
    provider.playables.add(song);

    await expectLater(
      provider.unlike(song),
      throwsA(anything),
    );

    expect(song.liked, isTrue);
    expect(provider.playables, contains(song));
  });

  // A downloaded song carries its own copy of the metadata on disk, restored
  // on the next launch. Without a re-write it comes back with the stale
  // `liked`, which is what the Now Playing sheet then shows.
  test('toggleOne re-persists the metadata of a downloaded song', () async {
    client.willReturn(json: {});
    final song = Song.fake(liked: false);

    await provider.toggleOne(playable: song);

    verify(downloadProviderMock.persistMetadataIfNeeded(song)).called(1);
  });

  test('unlike re-persists the metadata of a downloaded song', () async {
    client.willReturn(json: {});
    final song = Song.fake(liked: true);
    provider.playables.add(song);

    await provider.unlike(song);

    verify(downloadProviderMock.persistMetadataIfNeeded(song)).called(1);
  });

  test('a favorite that failed to save is not persisted', () async {
    client.willReturnRaw(status: 500, body: 'nope');
    final song = Song.fake(liked: false);

    await expectLater(
      provider.toggleOne(playable: song),
      throwsA(anything),
    );

    verifyNever(downloadProviderMock.persistMetadataIfNeeded(any));
  });

  test('an unlike that failed to save is not persisted', () async {
    client.willReturnRaw(status: 500, body: 'nope');
    final song = Song.fake(liked: true);
    provider.playables.add(song);

    await expectLater(
      provider.unlike(song),
      throwsA(anything),
    );

    verifyNever(downloadProviderMock.persistMetadataIfNeeded(any));
  });
}

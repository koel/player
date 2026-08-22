import 'package:app/audio_handler.dart';
import 'package:app/main.dart' as app;
import 'package:app/models/song.dart';
import 'package:app/providers/download_provider.dart';
import 'package:app/providers/interaction_provider.dart';
import 'package:app/providers/playable_provider.dart';
import 'package:app/providers/recently_played_provider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:rxdart/rxdart.dart';

import '../helpers/api_test_setup.dart';
import 'interaction_provider_test.mocks.dart';

@GenerateMocks([
  KoelAudioHandler,
  AudioPlayer,
  PlayableProvider,
  RecentlyPlayedProvider,
  DownloadProvider,
])
void main() {
  late MockPlayableProvider playableProviderMock;
  late MockRecentlyPlayedProvider recentlyPlayedProviderMock;
  late MockDownloadProvider downloadProviderMock;
  late BehaviorSubject<Duration> positionSubject;
  late CapturingClient client;
  late Song song;

  setUpAll(() async => await initApiTestEnvironment());

  setUp(() {
    // Song.fake() randomises length regardless of the argument, so pin it: the
    // play only registers past a quarter of the way through.
    song = Song.fake(liked: true, playCount: 3)..length = 100;

    positionSubject = BehaviorSubject<Duration>.seeded(Duration.zero);

    final playerMock = MockAudioPlayer();
    when(playerMock.positionStream).thenAnswer((_) => positionSubject);

    final audioHandlerMock = MockKoelAudioHandler();
    when(audioHandlerMock.playbackState)
        .thenAnswer((_) => BehaviorSubject<PlaybackState>.seeded(
              PlaybackState(),
            ));
    when(audioHandlerMock.mediaItem)
        .thenAnswer((_) => BehaviorSubject<MediaItem?>.seeded(
              MediaItem(id: song.id, title: song.title),
            ));
    when(audioHandlerMock.player).thenReturn(playerMock);
    app.audioHandler = audioHandlerMock;

    playableProviderMock = MockPlayableProvider();
    when(playableProviderMock.byId(song.id)).thenReturn(song);

    recentlyPlayedProviderMock = MockRecentlyPlayedProvider();
    downloadProviderMock = MockDownloadProvider();

    client = CapturingClient();
    client.install();
    setUpApiTest();
  });

  tearDown(() {
    positionSubject.close();
    tearDownApiTest();
  });

  InteractionProvider buildProvider() => InteractionProvider(
        playableProvider: playableProviderMock,
        recentlyPlayedProvider: recentlyPlayedProviderMock,
        downloadProvider: downloadProviderMock,
      );

  test('registering a play keeps the song favorite', () async {
    // The interaction endpoint carries no favorite state — that moved to a
    // separate resource — so a play must not be read as an unfavorite.
    client.willReturn(json: {
      'type': 'interactions',
      'id': 1,
      'song_id': song.id,
      'play_count': 17,
    });

    buildProvider();
    positionSubject.add(const Duration(seconds: 30));
    await pumpEventQueue();

    expect(
      client.requests.map((request) => request.url),
      contains(endsWith('interaction/play')),
    );
    expect(song.playCount, 17);
    expect(song.liked, isTrue);
  });
}

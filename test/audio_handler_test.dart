import 'dart:async';

import 'package:app/audio_handler.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/download_provider.dart';
import 'package:app/providers/playable_provider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'helpers/api_test_setup.dart';
import 'audio_handler_test.mocks.dart';

@GenerateMocks([AudioPlayer, PlayableProvider, DownloadProvider])
void main() {
  late MockAudioPlayer player;
  late MockPlayableProvider playableProvider;
  late MockDownloadProvider downloadProvider;
  late StreamController<PlaybackEvent> playbackEvents;
  late StreamController<ProcessingState> processingStates;
  late KoelAudioHandler handler;
  late CapturingClient client;

  setUpAll(() async => await initApiTestEnvironment());

  setUp(() async {
    playbackEvents = StreamController<PlaybackEvent>.broadcast();
    processingStates = StreamController<ProcessingState>.broadcast();

    player = MockAudioPlayer();
    when(player.playbackEventStream).thenAnswer((_) => playbackEvents.stream);
    when(player.processingStateStream)
        .thenAnswer((_) => processingStates.stream);
    when(player.processingState).thenReturn(ProcessingState.ready);
    when(player.playing).thenReturn(false);
    when(player.shuffleModeEnabled).thenReturn(false);
    when(player.position).thenReturn(Duration.zero);
    when(player.bufferedPosition).thenReturn(Duration.zero);
    when(player.speed).thenReturn(1.0);
    when(player.setVolume(any)).thenAnswer((_) async {});
    when(player.setFilePath(any)).thenAnswer((_) async => Duration.zero);
    when(player.setUrl(any)).thenAnswer((_) async => Duration.zero);
    when(player.seek(any)).thenAnswer((_) async {});
    when(player.play()).thenAnswer((_) async {});
    when(player.stop()).thenAnswer((_) async {});

    playableProvider = MockPlayableProvider();
    downloadProvider = MockDownloadProvider();
    when(downloadProvider.getForPlayable(any)).thenReturn(null);

    handler = KoelAudioHandler(
      player: player,
      sourceLoadTimeout: const Duration(milliseconds: 50),
    );

    client = CapturingClient();
    client.install();
    setUpApiTest();

    await handler.init(
      playableProvider: playableProvider,
      downloadProvider: downloadProvider,
    );
  });

  tearDown(() async {
    await playbackEvents.close();
    await processingStates.close();
    tearDownApiTest();
  });

  Song registerSong() {
    final song = Song.fake();
    when(playableProvider.byId(song.id)).thenReturn(song);
    return song;
  }

  AudioProcessingState currentProcessingState() =>
      handler.playbackState.value.processingState;

  test('streams a song that has not been downloaded', () async {
    final song = registerSong();

    await handler.replaceQueue([song]);

    verify(player.setUrl(song.sourceUrl)).called(1);
    verifyNever(player.setFilePath(any));
  });

  test('plays a downloaded song from its local file', () async {
    final song = registerSong();
    when(downloadProvider.getForPlayable(song))
        .thenReturn(Download(playable: song, path: '/downloads/song.mp3'));

    await handler.replaceQueue([song]);

    verify(player.setFilePath('/downloads/song.mp3')).called(1);
    verifyNever(player.setUrl(any));
  });

  test('gives up on a source that never becomes playable', () async {
    final song = registerSong();
    when(player.setUrl(any)).thenAnswer((_) => Completer<Duration?>().future);

    await handler.replaceQueue([song]);

    verify(player.stop()).called(1);
    expect(currentProcessingState(), AudioProcessingState.error);
  });

  test('reports a source that fails outright', () async {
    final song = registerSong();
    when(player.setUrl(any)).thenThrow(Exception('no route to host'));

    await handler.replaceQueue([song]);

    verify(player.stop()).called(1);
    expect(currentProcessingState(), AudioProcessingState.error);
  });

  test('skips past a song the server refuses to serve', () async {
    final broken = registerSong();
    final next = registerSong();
    when(player.setUrl(broken.sourceUrl)).thenThrow(Exception('404'));

    await handler.replaceQueue([broken, next]);

    verify(player.setUrl(next.sourceUrl)).called(1);
    expect(handler.mediaItem.value?.id, next.id);
    expect(currentProcessingState(), isNot(AudioProcessingState.error));
  });

  test('stays put when the load stalls instead of skipping', () async {
    final stalled = registerSong();
    final next = registerSong();
    when(player.setUrl(stalled.sourceUrl))
        .thenAnswer((_) => Completer<Duration?>().future);

    await handler.replaceQueue([stalled, next]);

    verifyNever(player.setUrl(next.sourceUrl));
    expect(handler.mediaItem.value?.id, stalled.id);
    expect(currentProcessingState(), AudioProcessingState.error);
  });

  test('gives up once too many songs fail in a row', () async {
    final songs = List.generate(
      KoelAudioHandler.MAX_ERROR_COUNT + 3,
      (_) => registerSong(),
    );
    when(player.setUrl(any)).thenThrow(Exception('404'));

    await handler.replaceQueue(songs);

    verify(player.setUrl(any)).called(KoelAudioHandler.MAX_ERROR_COUNT);
    expect(currentProcessingState(), AudioProcessingState.error);
  });

  test('stops skipping at the end of the queue', () async {
    final broken = registerSong();
    when(player.setUrl(any)).thenThrow(Exception('404'));

    await handler.replaceQueue([broken]);

    expect(currentProcessingState(), AudioProcessingState.error);
  });

  test('a song that plays clears the run of failures', () async {
    final songs = List.generate(6, (_) => registerSong());
    when(player.setUrl(any)).thenThrow(Exception('404'));
    when(player.setUrl(songs[1].sourceUrl))
        .thenAnswer((_) async => Duration.zero);

    // Fails on the first song, skips onto the second, which plays.
    await handler.replaceQueue(songs);
    expect(handler.mediaItem.value?.id, songs[1].id);

    // The three that follow get a full budget of their own, rather than
    // inheriting the failure that came before the song that played.
    await handler.skipToNext();

    verify(player.setUrl(songs[4].sourceUrl)).called(1);
    verifyNever(player.setUrl(songs[5].sourceUrl));
  });

  test('can still skip to the next song after a stalled load', () async {
    final stalled = registerSong();
    final next = registerSong();
    when(player.setUrl(stalled.sourceUrl))
        .thenAnswer((_) => Completer<Duration?>().future);

    await handler.replaceQueue([stalled, next]);
    expect(currentProcessingState(), AudioProcessingState.error);

    await handler.skipToNext();

    verify(player.setUrl(next.sourceUrl)).called(1);
    expect(currentProcessingState(), isNot(AudioProcessingState.error));
  });

  test('play retries the current song after a failed load', () async {
    final song = registerSong();
    final firstAttempt = Completer<Duration?>();
    when(player.setUrl(song.sourceUrl))
        .thenAnswer((_) => firstAttempt.future);

    await handler.replaceQueue([song]);
    expect(currentProcessingState(), AudioProcessingState.error);

    when(player.setUrl(song.sourceUrl)).thenAnswer((_) async => Duration.zero);
    await handler.play();

    verify(player.setUrl(song.sourceUrl)).called(2);
    expect(currentProcessingState(), isNot(AudioProcessingState.error));
  });

  test('surfaces an error emitted by the player itself', () async {
    final song = registerSong();
    await handler.replaceQueue([song]);
    expect(currentProcessingState(), isNot(AudioProcessingState.error));

    playbackEvents.addError(Exception('platform decoding failure'));
    await pumpEventQueue();

    expect(currentProcessingState(), AudioProcessingState.error);
    verify(player.stop()).called(1);
  });
}

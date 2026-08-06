import 'package:app/audio_handler.dart';
import 'package:app/main.dart' as app;
import 'package:app/models/song.dart';
import 'package:app/providers/playable_provider.dart';
import 'package:app/providers/radio_player_provider.dart';
import 'package:app/ui/widgets/mini_player.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

import '../../extensions/widget_tester_extension.dart';
import 'mini_player_test.mocks.dart';

@GenerateMocks([KoelAudioHandler, PlayableProvider, RadioPlayerProvider, AudioPlayer])
void main() {
  late MockKoelAudioHandler audioHandlerMock;
  late MockPlayableProvider playableProviderMock;
  late MockRadioPlayerProvider radioPlayerProviderMock;
  late BehaviorSubject<PlaybackState> playbackStateSubject;
  late BehaviorSubject<MediaItem?> mediaItemSubject;
  late Song song;

  setUp(() {
    // Short enough that MarqueeText doesn't need to scroll: its animation
    // timers outlive the widget tree and trip the test binding.
    song = Song.fake(title: 'Elevation');

    playbackStateSubject = BehaviorSubject<PlaybackState>.seeded(
      PlaybackState(),
    );
    mediaItemSubject = BehaviorSubject<MediaItem?>.seeded(
      MediaItem(id: song.id, title: song.title),
    );

    final playerMock = MockAudioPlayer();
    when(playerMock.positionStream).thenAnswer((_) => Stream.value(
          Duration.zero,
        ));

    audioHandlerMock = MockKoelAudioHandler();
    when(audioHandlerMock.playbackState).thenAnswer((_) => playbackStateSubject);
    when(audioHandlerMock.mediaItem).thenAnswer((_) => mediaItemSubject);
    when(audioHandlerMock.player).thenReturn(playerMock);
    app.audioHandler = audioHandlerMock;

    playableProviderMock = MockPlayableProvider();
    when(playableProviderMock.byId(song.id)).thenReturn(song);

    radioPlayerProviderMock = MockRadioPlayerProvider();
    when(radioPlayerProviderMock.active).thenReturn(false);
  });

  tearDown(() async {
    await playbackStateSubject.close();
    await mediaItemSubject.close();
  });

  Future<void> pumpWithState(
    WidgetTester tester,
    PlaybackState state,
  ) async {
    playbackStateSubject.add(state);

    await tester.pumpAppWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PlayableProvider>.value(
            value: playableProviderMock,
          ),
          ChangeNotifierProvider<RadioPlayerProvider>.value(
            value: radioPlayerProviderMock,
          ),
        ],
        child: const MiniPlayer(),
      ),
    );
    await tester.pump();
  }

  final errorIcon = find.byKey(MiniPlayer.playbackErrorIconKey);

  testWidgets('marks a song that failed to load', (tester) async {
    await pumpWithState(
      tester,
      PlaybackState(processingState: AudioProcessingState.error),
    );

    expect(errorIcon, findsOneWidget);
    expect(find.byType(SpinKitThreeBounce), findsNothing);
  });

  testWidgets('spins while a song is loading', (tester) async {
    await pumpWithState(
      tester,
      PlaybackState(
        processingState: AudioProcessingState.loading,
        playing: true,
      ),
    );

    expect(find.byType(SpinKitThreeBounce), findsOneWidget);
    expect(errorIcon, findsNothing);
  });

  testWidgets('shows no overlay once a song is playing', (tester) async {
    await pumpWithState(
      tester,
      PlaybackState(
        processingState: AudioProcessingState.ready,
        playing: true,
      ),
    );

    expect(errorIcon, findsNothing);
    expect(find.byType(SpinKitThreeBounce), findsNothing);
  });
}

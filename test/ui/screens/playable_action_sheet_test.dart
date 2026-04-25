import 'package:app/audio_handler.dart';
import 'package:app/main.dart' as app;
import 'package:app/models/song.dart';
import 'package:app/providers/download_provider.dart';
import 'package:app/providers/favorite_provider.dart';
import 'package:app/ui/screens/playable_action_sheet.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

import '../../extensions/widget_tester_extension.dart';
import 'playable_action_sheet_test.mocks.dart';

@GenerateMocks([KoelAudioHandler, DownloadProvider, FavoriteProvider])
void main() {
  late MockKoelAudioHandler audioHandlerMock;
  late MockDownloadProvider downloadProviderMock;
  late MockFavoriteProvider favoriteProviderMock;
  late BehaviorSubject<MediaItem?> mediaItemSubject;
  late Song song;

  setUp(() {
    audioHandlerMock = MockKoelAudioHandler();
    downloadProviderMock = MockDownloadProvider();
    favoriteProviderMock = MockFavoriteProvider();
    song = Song.fake();

    mediaItemSubject = BehaviorSubject<MediaItem?>.seeded(null);
    when(audioHandlerMock.mediaItem).thenAnswer((_) => mediaItemSubject);
    when(audioHandlerMock.queued(song)).thenAnswer((_) async => false);

    app.audioHandler = audioHandlerMock;
  });

  tearDown(() {
    mediaItemSubject.close();
  });

  Future<void> _mountSheet(
    WidgetTester tester, {
    required bool downloaded,
  }) async {
    when(downloadProviderMock.has(playable: song)).thenReturn(downloaded);

    await tester.pumpAppWidget(
      MultiProvider(
        providers: [
          Provider<DownloadProvider>.value(value: downloadProviderMock),
          ChangeNotifierProvider<FavoriteProvider>.value(
            value: favoriteProviderMock,
          ),
        ],
        child: PlayableActionSheet(playable: song),
      ),
    );
  }

  testWidgets(
    'shows "Download" when the song is not downloaded',
    (tester) async {
      await _mountSheet(tester, downloaded: false);

      expect(find.text('Download'), findsOneWidget);
      expect(find.text('Remove Download'), findsNothing);
    },
  );

  testWidgets(
    'shows "Remove Download" when the song is downloaded',
    (tester) async {
      await _mountSheet(tester, downloaded: true);

      expect(find.text('Remove Download'), findsOneWidget);
      expect(find.text('Download'), findsNothing);
    },
  );

  testWidgets(
    'tapping "Download" delegates to DownloadProvider.download',
    (tester) async {
      when(downloadProviderMock.download(playable: song))
          .thenAnswer((_) async {});

      await _mountSheet(tester, downloaded: false);
      await tester.tap(find.text('Download'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      verify(downloadProviderMock.download(playable: song)).called(1);
      verifyNever(downloadProviderMock.removeForPlayable(song));
    },
  );

  testWidgets(
    'tapping "Remove Download" delegates to DownloadProvider.removeForPlayable',
    (tester) async {
      when(downloadProviderMock.removeForPlayable(song))
          .thenAnswer((_) async {});

      await _mountSheet(tester, downloaded: true);
      await tester.tap(find.text('Remove Download'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      verify(downloadProviderMock.removeForPlayable(song)).called(1);
      verifyNever(downloadProviderMock.download(playable: song));
    },
  );

  testWidgets(
    'tapping "Favorite" toggles via FavoriteProvider',
    (tester) async {
      when(favoriteProviderMock.toggleOne(playable: song))
          .thenAnswer((_) async {});

      await _mountSheet(tester, downloaded: false);
      await tester.tap(find.text('Favorite'));
      await tester.pump();

      verify(favoriteProviderMock.toggleOne(playable: song)).called(1);
    },
  );
}

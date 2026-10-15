import 'dart:async';

import 'package:app/audio_handler.dart';
import 'package:app/main.dart' as app;
import 'package:app/models/models.dart';
import 'package:app/providers/download_provider.dart';
import 'package:app/providers/playable_provider.dart';
import 'package:app/ui/screens/downloaded.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

import '../../extensions/widget_tester_extension.dart';
import 'downloaded_test.mocks.dart';

@GenerateMocks([KoelAudioHandler, DownloadProvider])
void main() {
  late MockKoelAudioHandler audioHandlerMock;
  late MockDownloadProvider downloadProviderMock;
  late StreamController<Playable> downloadRemoved;
  late StreamController<bool> downloadsCleared;
  late StreamController<Download> playableDownloaded;
  late List<Playable> downloads;

  setUp(() {
    audioHandlerMock = MockKoelAudioHandler();
    when(audioHandlerMock.playbackState)
        .thenAnswer((_) => BehaviorSubject.seeded(PlaybackState()));
    when(audioHandlerMock.mediaItem)
        .thenAnswer((_) => BehaviorSubject<MediaItem?>.seeded(null));
    app.audioHandler = audioHandlerMock;

    downloadRemoved = StreamController<Playable>.broadcast();
    downloadsCleared = StreamController<bool>.broadcast();
    playableDownloaded = StreamController<Download>.broadcast();

    downloadProviderMock = MockDownloadProvider();
    when(downloadProviderMock.downloadRemovedStream)
        .thenAnswer((_) => downloadRemoved.stream);
    when(downloadProviderMock.downloadsClearedStream)
        .thenAnswer((_) => downloadsCleared.stream);
    when(downloadProviderMock.playableDownloadedStream)
        .thenAnswer((_) => playableDownloaded.stream);
    when(downloadProviderMock.playables).thenAnswer((_) => downloads);
  });

  tearDown(() {
    downloadRemoved.close();
    downloadsCleared.close();
    playableDownloaded.close();
  });

  Future<void> _mountScreen(WidgetTester tester) async {
    await tester.pumpAppWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PlayableProvider>(
            create: (_) => PlayableProvider(),
          ),
          Provider<DownloadProvider>.value(value: downloadProviderMock),
        ],
        child: DownloadedScreen(),
      ),
      surfaceSize: const Size(500, 900),
    );
    await tester.pump();
  }

  testWidgets(
    'drops a song from the list when its download is removed elsewhere',
    (tester) async {
      final kept = Song.fake(title: 'Kept Song');
      final removed = Song.fake(title: 'Removed Song');
      downloads = [kept, removed];

      await _mountScreen(tester);
      expect(find.text('Kept Song'), findsOneWidget);
      expect(find.text('Removed Song'), findsOneWidget);

      downloads = [kept];
      downloadRemoved.add(removed);
      await tester.pumpAndSettle();

      expect(find.text('Removed Song'), findsNothing);
      expect(find.text('Kept Song'), findsOneWidget);
    },
  );

  testWidgets(
    'shows the empty state when all downloads are cleared elsewhere',
    (tester) async {
      downloads = [Song.fake(title: 'Only Song')];

      await _mountScreen(tester);
      expect(find.text('Only Song'), findsOneWidget);

      downloads = [];
      downloadsCleared.add(true);
      await tester.pumpAndSettle();

      expect(find.text('No downloaded songs'), findsOneWidget);
    },
  );
}

import 'package:app/models/song.dart';
import 'package:app/providers/download_provider.dart';
import 'package:app/ui/widgets/playable_cache_icon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

import '../../extensions/widget_tester_extension.dart';
import 'song_cache_icon_test.mocks.dart';

@GenerateMocks([DownloadProvider])
void main() {
  late MockDownloadProvider downloadMock;
  late Song song;
  late BehaviorSubject<bool> cacheCleared;
  late BehaviorSubject<Download> playableDownloaded;
  late BehaviorSubject<Song> downloadRemoved;

  setUp(() {
    downloadMock = MockDownloadProvider();
    song = Song.fake();

    cacheCleared = BehaviorSubject();
    when(downloadMock.downloadsClearedStream)
        .thenAnswer((_) => cacheCleared.stream);

    playableDownloaded = BehaviorSubject();
    when(downloadMock.playableDownloadedStream)
        .thenAnswer((_) => playableDownloaded.stream);

    downloadRemoved = BehaviorSubject();
    when(downloadMock.downloadRemovedStream)
        .thenAnswer((_) => downloadRemoved.stream);
  });

  Future<void> _mount(WidgetTester tester) async {
    await tester.pumpAppWidget(
      Provider<DownloadProvider>.value(
        value: downloadMock,
        child: PlayableCacheIcon(playable: song),
      ),
    );
  }

  void _assertCacheStatus({required bool hasCache}) {
    if (hasCache) {
      expect(find.byIcon(CupertinoIcons.cloud_download_fill), findsNothing);
      expect(
        find.byIcon(CupertinoIcons.checkmark_alt_circle_fill),
        findsOneWidget,
      );
    } else {
      expect(find.byIcon(CupertinoIcons.cloud_download_fill), findsOneWidget);
      expect(
        find.byIcon(CupertinoIcons.checkmark_alt_circle_fill),
        findsNothing,
      );
    }
  }

  testWidgets(
    'renders a download button if song is not cached',
    (WidgetTester tester) async {
      when(downloadMock.has(playable: song)).thenReturn(false);

      await _mount(tester);
      _assertCacheStatus(hasCache: false);
    },
  );

  testWidgets(
    'renders a "downloaded" indicator if song is cached',
    (WidgetTester tester) async {
      when(downloadMock.has(playable: song)).thenReturn(true);

      await _mount(tester);
      _assertCacheStatus(hasCache: true);
    },
  );

  testWidgets('re-renders when cache is cleared', (WidgetTester tester) async {
    when(downloadMock.has(playable: song)).thenReturn(true);

    await _mount(tester);
    _assertCacheStatus(hasCache: true);

    when(downloadMock.has(playable: song)).thenReturn(false);
    cacheCleared.add(true);
    await tester.pumpAndSettle();
    _assertCacheStatus(hasCache: false);
  });

  testWidgets('re-renders when song is cached', (WidgetTester tester) async {
    when(downloadMock.has(playable: song)).thenReturn(false);

    await _mount(tester);
    _assertCacheStatus(hasCache: false);

    when(downloadMock.has(playable: song)).thenReturn(true);
    playableDownloaded.add(Download(playable: song, path: '/tmp/test.mp3'));
    await tester.pumpAndSettle();
    _assertCacheStatus(hasCache: true);
  });

  testWidgets(
    're-renders when song cache is removed',
    (WidgetTester tester) async {
      when(downloadMock.has(playable: song)).thenReturn(true);

      await _mount(tester);
      _assertCacheStatus(hasCache: true);

      when(downloadMock.has(playable: song)).thenReturn(false);
      downloadRemoved.add(song);
      await tester.pumpAndSettle();
      _assertCacheStatus(hasCache: false);
    },
  );
}

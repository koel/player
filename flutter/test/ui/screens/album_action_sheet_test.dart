import 'package:app/app_state.dart';
import 'package:app/audio_handler.dart';
import 'package:app/main.dart' as app;
import 'package:app/models/album.dart';
import 'package:app/models/artist.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/album_provider.dart';
import 'package:app/providers/playable_provider.dart';
import 'package:app/ui/screens/album_action_sheet.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:version/version.dart';

import '../../extensions/widget_tester_extension.dart';
import 'album_action_sheet_test.mocks.dart';

@GenerateMocks([KoelAudioHandler, AlbumProvider, PlayableProvider])
void main() {
  late MockKoelAudioHandler audioHandlerMock;
  late MockAlbumProvider albumProviderMock;
  late MockPlayableProvider playableProviderMock;
  late BehaviorSubject<MediaItem?> mediaItemSubject;

  setUp(() {
    AppState.clear();
    // Default to a koel version where the per-entity favorite feature
    // is supported; individual tests override when they need older.
    AppState.set(['app', 'apiVersion'], Version.parse('7.11.0'));

    audioHandlerMock = MockKoelAudioHandler();
    albumProviderMock = MockAlbumProvider();
    playableProviderMock = MockPlayableProvider();

    mediaItemSubject = BehaviorSubject<MediaItem?>.seeded(null);
    when(audioHandlerMock.mediaItem).thenAnswer((_) => mediaItemSubject);
    when(audioHandlerMock.queued(any)).thenAnswer((_) async => false);
    when(audioHandlerMock.queueAfterCurrent(any)).thenAnswer((_) async {});
    when(audioHandlerMock.queueToBottom(any)).thenAnswer((_) async {});
    when(audioHandlerMock.replaceQueue(
      any,
      shuffle: anyNamed('shuffle'),
      autoPlay: anyNamed('autoPlay'),
    )).thenAnswer((_) async {});

    app.audioHandler = audioHandlerMock;
  });

  tearDown(() {
    mediaItemSubject.close();
  });

  Future<void> mount(WidgetTester tester, Album album) async {
    await tester.pumpAppWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AlbumProvider>.value(value: albumProviderMock),
          ChangeNotifierProvider<PlayableProvider>.value(
            value: playableProviderMock,
          ),
        ],
        child: AlbumActionSheet(album: album),
      ),
    );
  }

  group('structure', () {
    testWidgets('renders album name and artist name', (tester) async {
      final album = Album.fake(
        name: 'Abbey Road',
        artist: Artist.fake(name: 'The Beatles'),
      );
      await mount(tester, album);

      expect(find.text('Abbey Road'), findsOneWidget);
      expect(find.text('The Beatles'), findsOneWidget);
    });

    testWidgets('renders the three quick actions', (tester) async {
      await mount(tester, Album.fake(name: 'A'));

      expect(find.text('Favorite'), findsOneWidget);
      expect(find.text('Play All'), findsOneWidget);
      expect(find.text('Shuffle All'), findsOneWidget);
    });

    testWidgets('shows "Undo Favorite" when album.favorite is true',
        (tester) async {
      await mount(tester, Album.fake(name: 'Loved', favorite: true));

      expect(find.text('Undo Favorite'), findsOneWidget);
      expect(find.text('Favorite'), findsNothing);
    });

    testWidgets('shows Edit only when canEdit is true', (tester) async {
      await mount(tester, Album.fake(name: 'Editable', canEdit: true));
      expect(find.text('Edit…'), findsOneWidget);
    });

    testWidgets('hides Edit when canEdit is false', (tester) async {
      await mount(tester, Album.fake(name: 'Read-only'));
      expect(find.text('Edit…'), findsNothing);
    });

    testWidgets('hides Go to Artist for Unknown Artist albums',
        (tester) async {
      final album = Album.fake(
        name: 'Mystery',
        artist: Artist.fake(name: 'Unknown Artist'),
      );
      await mount(tester, album);
      expect(find.text('Go to Artist'), findsNothing);
    });

    testWidgets('hides Go to Artist for Various Artists albums',
        (tester) async {
      final album = Album.fake(
        name: 'Compilation',
        artist: Artist.fake(name: 'Various Artists'),
      );
      await mount(tester, album);
      expect(find.text('Go to Artist'), findsNothing);
    });

    testWidgets('shows Go to Artist for a normal artist', (tester) async {
      final album = Album.fake(
        name: 'Real',
        artist: Artist.fake(name: 'Pink Floyd'),
      );
      await mount(tester, album);
      expect(find.text('Go to Artist'), findsOneWidget);
    });

    testWidgets(
      'hides Favorite when the koel version is below 7.11.0',
      (tester) async {
        AppState.set(['app', 'apiVersion'], Version.parse('7.10.0'));

        await mount(tester, Album.fake(name: 'A'));

        expect(find.text('Favorite'), findsNothing);
        expect(find.text('Undo Favorite'), findsNothing);
        // The other two stay.
        expect(find.text('Play All'), findsOneWidget);
        expect(find.text('Shuffle All'), findsOneWidget);
      },
    );
  });

  group('actions', () {
    testWidgets('tapping Favorite delegates to AlbumProvider.toggleFavorite',
        (tester) async {
      final album = Album.fake(name: 'Loved');
      when(albumProviderMock.toggleFavorite(album)).thenAnswer((_) async {});

      await mount(tester, album);
      await tester.tap(find.text('Favorite'));
      await tester.pump();

      verify(albumProviderMock.toggleFavorite(album)).called(1);
    });

    testWidgets('tapping Play All replaces the queue without shuffling',
        (tester) async {
      final album = Album.fake(name: 'A');
      final songs = Song.fakeMany(3);
      when(playableProviderMock.fetchForAlbum(album.id))
          .thenAnswer((_) async => songs);

      await mount(tester, album);
      await tester.tap(find.text('Play All'));
      // First pump runs the synchronous parts of onTap; second pump
      // settles the async fetch and replaceQueue.
      await tester.pumpAndSettle();

      verify(playableProviderMock.fetchForAlbum(album.id)).called(1);
      verify(audioHandlerMock.replaceQueue(songs)).called(1);
    });

    testWidgets('tapping Shuffle All replaces the queue with shuffle',
        (tester) async {
      final album = Album.fake(name: 'A');
      final songs = Song.fakeMany(3);
      when(playableProviderMock.fetchForAlbum(album.id))
          .thenAnswer((_) async => songs);

      await mount(tester, album);
      await tester.tap(find.text('Shuffle All'));
      await tester.pumpAndSettle();

      verify(playableProviderMock.fetchForAlbum(album.id)).called(1);
      verify(audioHandlerMock.replaceQueue(songs, shuffle: true)).called(1);
    });

    testWidgets(
      'tapping Play Next inserts songs in reverse so the queue ends up '
      'in album order',
      (tester) async {
        final album = Album.fake(name: 'A');
        final songs = Song.fakeMany(3);
        when(playableProviderMock.fetchForAlbum(album.id))
            .thenAnswer((_) async => songs);

        await mount(tester, album);
        await tester.tap(find.text('Play Next'));
        await tester.pumpAndSettle();
        // Flush the showOverlay's auto-dismiss timer so the test
        // tear-down doesn't complain about pending timers.
        await tester.pump(const Duration(seconds: 3));

        // queueAfterCurrent inserts at a fixed 'after current' index,
        // so to land in album order [0, 1, 2] the implementation has
        // to call them in reverse: 2, then 1, then 0.
        verifyInOrder([
          audioHandlerMock.queueAfterCurrent(songs[2]),
          audioHandlerMock.queueAfterCurrent(songs[1]),
          audioHandlerMock.queueAfterCurrent(songs[0]),
        ]);
        verifyNever(audioHandlerMock.queueToBottom(any));
      },
    );

    testWidgets(
      'tapping Play Last appends songs in album order',
      (tester) async {
        final album = Album.fake(name: 'A');
        final songs = Song.fakeMany(3);
        when(playableProviderMock.fetchForAlbum(album.id))
            .thenAnswer((_) async => songs);

        await mount(tester, album);
        await tester.tap(find.text('Play Last'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));

        verifyInOrder([
          audioHandlerMock.queueToBottom(songs[0]),
          audioHandlerMock.queueToBottom(songs[1]),
          audioHandlerMock.queueToBottom(songs[2]),
        ]);
        verifyNever(audioHandlerMock.queueAfterCurrent(any));
      },
    );
  });
}

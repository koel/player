import 'dart:async';

import 'package:app/app_state.dart';
import 'package:app/audio_handler.dart';
import 'package:app/main.dart' as app;
import 'package:app/models/podcast.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/playable_provider.dart';
import 'package:app/providers/podcast_provider.dart';
import 'package:app/ui/screens/podcast_action_sheet.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:version/version.dart';

import '../../extensions/widget_tester_extension.dart';
import 'podcast_action_sheet_test.mocks.dart';

@GenerateMocks([KoelAudioHandler, PodcastProvider, PlayableProvider])
void main() {
  late MockKoelAudioHandler audioHandlerMock;
  late MockPodcastProvider podcastProviderMock;
  late MockPlayableProvider playableProviderMock;
  late BehaviorSubject<MediaItem?> mediaItemSubject;

  setUp(() {
    AppState.clear();
    AppState.set(['app', 'apiVersion'], Version.parse('7.11.0'));

    audioHandlerMock = MockKoelAudioHandler();
    podcastProviderMock = MockPodcastProvider();
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
    when(audioHandlerMock.maybeQueueAndPlay(any))
        .thenAnswer((_) async {});

    app.audioHandler = audioHandlerMock;
  });

  tearDown(() {
    mediaItemSubject.close();
  });

  Future<void> mount(WidgetTester tester, Podcast podcast) async {
    // Mirror production wiring:
    //  - MultiProvider sits ABOVE MaterialApp so contexts captured via
    //    `Navigator.of(rootNavigator: true)` can find the providers.
    //  - The sheet is pushed via `showModalBottomSheet` rather than
    //    rendered as `home`, so `Navigator.pop` actually pops the
    //    modal route and the suite exercises the real route boundary
    //    that the post-pop toast logic depends on.
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PodcastProvider>.value(
            value: podcastProviderMock,
          ),
          ChangeNotifierProvider<PlayableProvider>.value(
            value: playableProviderMock,
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Material(
              child: TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  useRootNavigator: true,
                  isScrollControlled: true,
                  builder: (_) => PodcastActionSheet(podcast: podcast),
                ),
                child: const Text('Open sheet'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();
  }

  group('structure', () {
    testWidgets('renders title and author', (tester) async {
      await mount(
        tester,
        Podcast.fake(title: 'My Show', author: 'Jane Doe'),
      );

      expect(find.text('My Show'), findsOneWidget);
      expect(find.text('Jane Doe'), findsOneWidget);
    });

    testWidgets('renders description, capped at 3 lines with ellipsis',
        (tester) async {
      // A long description so we can assert truncation actually applies.
      const description =
          'A long-running show about coffee, code, and everything in '
          'between. Each episode dives into a different topic from the '
          'industry, with guests, interviews, and stories from listeners. '
          'The hosts have been at it for years and have hundreds of '
          'episodes to show for it, covering every corner of the field.';
      final podcast = Podcast.fake(title: 'My Show');
      // description is final on the model; build a podcast with it via
      // the named ctor below.
      final p = Podcast(
        id: podcast.id,
        title: podcast.title,
        url: podcast.url,
        link: podcast.link,
        description: description,
        author: podcast.author,
        imageUrl: podcast.imageUrl,
        subscribedAt: podcast.subscribedAt,
        lastPlayedAt: podcast.lastPlayedAt,
        state: podcast.state,
      );

      await mount(tester, p);

      final descFinder = find.text(description);
      expect(descFinder, findsOneWidget);
      final widget = tester.widget<Text>(descFinder);
      expect(widget.maxLines, 3);
      expect(widget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('omits description when empty', (tester) async {
      final base = Podcast.fake();
      final p = Podcast(
        id: base.id,
        title: base.title,
        url: base.url,
        link: base.link,
        description: '',
        author: base.author,
        imageUrl: base.imageUrl,
        subscribedAt: base.subscribedAt,
        lastPlayedAt: base.lastPlayedAt,
        state: base.state,
      );

      await mount(tester, p);

      // No empty Text widget gets rendered for the description slot.
      // (Title + author + the action labels are still present.)
      expect(find.text(''), findsNothing);
    });

    testWidgets(
      'shows "Play All" when there is no current episode',
      (tester) async {
        await mount(tester, Podcast.fake(title: 'A'));

        expect(find.text('Play All'), findsOneWidget);
        expect(find.text('Continue'), findsNothing);
      },
    );

    testWidgets(
      'shows "Continue" when there is a current episode',
      (tester) async {
        final podcast = Podcast.fake(
          title: 'A',
          state: PodcastState(
            currentEpisodeId: 'ep-mid',
            progresses: {'ep-mid': 120},
          ),
        );
        await mount(tester, podcast);

        expect(find.text('Continue'), findsOneWidget);
        expect(find.text('Play All'), findsNothing);
      },
    );

    testWidgets('renders Favorite + Shuffle in the quick row', (tester) async {
      await mount(tester, Podcast.fake());

      expect(find.text('Favorite'), findsOneWidget);
      expect(find.text('Shuffle'), findsOneWidget);
    });

    testWidgets('shows "Undo Favorite" when podcast.favorite is true',
        (tester) async {
      await mount(tester, Podcast.fake(favorite: true));

      expect(find.text('Undo Favorite'), findsOneWidget);
      expect(find.text('Favorite'), findsNothing);
    });

    testWidgets(
      'hides Favorite when koel version is below 7.11.0',
      (tester) async {
        AppState.set(['app', 'apiVersion'], Version.parse('7.10.0'));

        await mount(tester, Podcast.fake());

        expect(find.text('Favorite'), findsNothing);
        expect(find.text('Undo Favorite'), findsNothing);
        // Play All / Shuffle stay.
        expect(find.text('Play All'), findsOneWidget);
        expect(find.text('Shuffle'), findsOneWidget);
      },
    );

    testWidgets('renders Refresh and Unsubscribe rows', (tester) async {
      await mount(tester, Podcast.fake());

      expect(find.text('Refresh'), findsOneWidget);
      expect(find.text('Unsubscribe'), findsOneWidget);
    });
  });

  group('actions', () {
    testWidgets(
      'tapping Favorite delegates to PodcastProvider.toggleFavorite',
      (tester) async {
        final podcast = Podcast.fake();
        when(podcastProviderMock.toggleFavorite(podcast))
            .thenAnswer((_) async {});

        await mount(tester, podcast);
        await tester.tap(find.text('Favorite'));
        await tester.pump();

        verify(podcastProviderMock.toggleFavorite(podcast)).called(1);
      },
    );

    testWidgets(
      'tapping Play All replaces the queue without shuffling',
      (tester) async {
        final podcast = Podcast.fake();
        final episodes = Song.fakeMany(3);
        when(playableProviderMock.fetchForPodcast(
          podcast.id,
          forceRefresh: anyNamed('forceRefresh'),
          getUpdates: anyNamed('getUpdates'),
        )).thenAnswer((_) async => episodes);

        await mount(tester, podcast);
        await tester.tap(find.text('Play All'));
        await tester.pumpAndSettle();

        verify(audioHandlerMock.replaceQueue(episodes)).called(1);
        verifyNever(audioHandlerMock.maybeQueueAndPlay(any));
      },
    );

    testWidgets(
      'tapping Continue queues all episodes silently and resumes the current one',
      (tester) async {
        final podcast = Podcast.fake(
          state: PodcastState(
            currentEpisodeId: 'ep-mid',
            progresses: {'ep-mid': 30},
          ),
        );
        final ep1 = Song.fake(id: 'ep-1');
        final epMid = Song.fake(id: 'ep-mid');
        final ep3 = Song.fake(id: 'ep-3');
        final episodes = [ep1, epMid, ep3];
        when(playableProviderMock.fetchForPodcast(
          podcast.id,
          forceRefresh: anyNamed('forceRefresh'),
          getUpdates: anyNamed('getUpdates'),
        )).thenAnswer((_) async => episodes);

        await mount(tester, podcast);
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        verify(audioHandlerMock.replaceQueue(
          episodes,
          autoPlay: false,
        )).called(1);
        verify(audioHandlerMock.maybeQueueAndPlay(epMid)).called(1);
      },
    );

    testWidgets(
      'tapping Continue falls back to Play All when the current episode is missing',
      (tester) async {
        final podcast = Podcast.fake(
          state: PodcastState(
            currentEpisodeId: 'gone',
            progresses: {'gone': 30},
          ),
        );
        final episodes = Song.fakeMany(2);
        when(playableProviderMock.fetchForPodcast(
          podcast.id,
          forceRefresh: anyNamed('forceRefresh'),
          getUpdates: anyNamed('getUpdates'),
        )).thenAnswer((_) async => episodes);

        await mount(tester, podcast);
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        verify(audioHandlerMock.replaceQueue(episodes)).called(1);
        verifyNever(audioHandlerMock.maybeQueueAndPlay(any));
      },
    );

    testWidgets(
      'tapping Shuffle replaces the queue with shuffle',
      (tester) async {
        final podcast = Podcast.fake();
        final episodes = Song.fakeMany(3);
        when(playableProviderMock.fetchForPodcast(
          podcast.id,
          forceRefresh: anyNamed('forceRefresh'),
          getUpdates: anyNamed('getUpdates'),
        )).thenAnswer((_) async => episodes);

        await mount(tester, podcast);
        await tester.tap(find.text('Shuffle'));
        await tester.pumpAndSettle();

        verify(audioHandlerMock.replaceQueue(
          episodes,
          shuffle: true,
        )).called(1);
      },
    );

    testWidgets(
      'Refresh shows a spinner while in flight, then dismisses + toasts',
      (tester) async {
        final podcast = Podcast.fake();
        final completer = Completer<List<Song>>();
        when(playableProviderMock.fetchForPodcast(
          podcast.id,
          forceRefresh: anyNamed('forceRefresh'),
          getUpdates: anyNamed('getUpdates'),
        )).thenAnswer((_) => completer.future);

        await mount(tester, podcast);
        await tester.tap(find.text('Refresh'));
        await tester.pump();

        // While the fetch is pending the row replaces its label with
        // "Refreshing…" and shows a spinner; the sheet stays open.
        expect(find.text('Refresh'), findsNothing);
        expect(find.text('Refreshing…'), findsOneWidget);
        expect(find.byType(CupertinoActivityIndicator), findsOneWidget);

        // Resolve. Sheet pops, success toast appears.
        completer.complete(<Song>[]);
        await tester.pumpAndSettle();

        verify(playableProviderMock.fetchForPodcast(
          podcast.id,
          forceRefresh: true,
          getUpdates: true,
        )).called(1);
        expect(find.text('Refreshing…'), findsNothing);
        expect(find.text('Feed refreshed'), findsOneWidget);

        // Drain showOverlay's auto-dismiss timer.
        await tester.pump(const Duration(seconds: 3));
      },
    );

    testWidgets(
      'Refresh shows an error overlay when the fetch throws',
      (tester) async {
        final podcast = Podcast.fake();
        when(playableProviderMock.fetchForPodcast(
          podcast.id,
          forceRefresh: anyNamed('forceRefresh'),
          getUpdates: anyNamed('getUpdates'),
        )).thenThrow(Exception('boom'));

        await mount(tester, podcast);
        await tester.tap(find.text('Refresh'));
        await tester.pumpAndSettle();

        expect(find.text('Refresh failed'), findsOneWidget);
        expect(find.text('Feed refreshed'), findsNothing);

        // Drain showOverlay's auto-dismiss timer.
        await tester.pump(const Duration(seconds: 3));
      },
    );

    testWidgets(
      'other rows are disabled while a refresh is in flight',
      (tester) async {
        final podcast = Podcast.fake();
        final completer = Completer<List<Song>>();
        when(playableProviderMock.fetchForPodcast(
          podcast.id,
          forceRefresh: anyNamed('forceRefresh'),
          getUpdates: anyNamed('getUpdates'),
        )).thenAnswer((_) => completer.future);

        await mount(tester, podcast);
        await tester.tap(find.text('Refresh'));
        await tester.pump();

        // While in flight, tapping the other actions should be a no-op
        // (rows are visually dimmed and onTap is null).
        await tester.tap(find.text('Favorite'));
        await tester.tap(find.text('Play All'));
        await tester.tap(find.text('Shuffle'));
        await tester.tap(find.text('Unsubscribe'));
        await tester.pump();

        verifyNever(podcastProviderMock.toggleFavorite(any));
        verifyNever(audioHandlerMock.replaceQueue(
          any,
          shuffle: anyNamed('shuffle'),
          autoPlay: anyNamed('autoPlay'),
        ));
        // Confirm dialog must NOT have opened.
        expect(find.text('Unsubscribe?'), findsNothing);

        // Resolve so the test exits cleanly.
        completer.complete(<Song>[]);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));
      },
    );

    testWidgets(
      'dismissing the sheet mid-refresh still surfaces the toast on completion',
      (tester) async {
        final podcast = Podcast.fake();
        final completer = Completer<List<Song>>();
        when(playableProviderMock.fetchForPodcast(
          podcast.id,
          forceRefresh: anyNamed('forceRefresh'),
          getUpdates: anyNamed('getUpdates'),
        )).thenAnswer((_) => completer.future);

        await mount(tester, podcast);
        await tester.tap(find.text('Refresh'));
        await tester.pump();
        expect(find.text('Refreshing…'), findsOneWidget);

        // Simulate the user swiping the sheet away while refresh is in
        // flight: pop the sheet's route directly.
        final sheetContext = tester.element(find.byType(PodcastActionSheet));
        Navigator.of(sheetContext).pop();
        await tester.pumpAndSettle();
        expect(find.byType(PodcastActionSheet), findsNothing);

        // Now resolve. Even though the sheet is gone, the toast still
        // appears because we captured the root navigator's context
        // before pop.
        completer.complete(<Song>[]);
        await tester.pumpAndSettle();

        expect(find.text('Feed refreshed'), findsOneWidget);
        await tester.pump(const Duration(seconds: 3));
      },
    );

    testWidgets(
      'tapping Unsubscribe shows a confirm dialog and delegates on confirm',
      (tester) async {
        final podcast = Podcast.fake(title: 'Bye');
        when(podcastProviderMock.unsubscribePodcast(podcast))
            .thenAnswer((_) async {});

        await mount(tester, podcast);
        await tester.tap(find.text('Unsubscribe'));
        await tester.pumpAndSettle();

        // Confirm dialog is up.
        expect(find.text('Unsubscribe?'), findsOneWidget);

        // Tap the dialog's Unsubscribe button.
        await tester
            .tap(find.widgetWithText(CupertinoDialogAction, 'Unsubscribe'));
        await tester.pumpAndSettle();

        verify(podcastProviderMock.unsubscribePodcast(podcast)).called(1);
        expect(find.text('Unsubscribed'), findsOneWidget);
        await tester.pump(const Duration(seconds: 3));
      },
    );

    testWidgets(
      'cancelling the Unsubscribe confirm leaves the podcast alone',
      (tester) async {
        final podcast = Podcast.fake(title: 'Stay');

        await mount(tester, podcast);
        await tester.tap(find.text('Unsubscribe'));
        await tester.pumpAndSettle();

        await tester
            .tap(find.widgetWithText(CupertinoDialogAction, 'Cancel'));
        await tester.pumpAndSettle();

        verifyNever(podcastProviderMock.unsubscribePodcast(any));
        // Sheet is still open.
        expect(find.byType(PodcastActionSheet), findsOneWidget);
      },
    );
  });
}

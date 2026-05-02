import 'package:app/app_state.dart';
import 'package:app/providers/playable_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/api_test_setup.dart';

Map<String, dynamic> _episodeJson(String id, {int track = 1}) => {
      'type': 'episodes',
      'id': id,
      'length': 600,
      'title': 'Episode $track',
      'podcast_id': 'pod-1',
      'podcast_title': 'Show',
      'podcast_author': 'Author',
      'episode_description': 'desc',
      'episode_image': 'https://example.com/ep.jpg',
      'episode_link': 'https://example.com/ep',
      'created_at': '2026-01-0${track}T00:00:00Z',
    };

void main() {
  setUpAll(initApiTestEnvironment);
  setUp(() {
    setUpApiTest();
    AppState.clear();
  });
  tearDown(tearDownApiTest);

  group('PlayableProvider.fetchForPodcast', () {
    test(
      'GETs /podcasts/<id>/episodes and caches the result on first call',
      () async {
        final http = CapturingClient()
          ..willReturn(json: [_episodeJson('e-1'), _episodeJson('e-2')])
          ..install();

        final episodes = await PlayableProvider().fetchForPodcast('pod-1');

        final req = http.requests.single;
        expect(req.method, 'GET');
        expect(req.url, 'https://koel.test/api/podcasts/pod-1/episodes');
        expect(episodes.map((e) => e.id), ['e-1', 'e-2']);
        expect(AppState.has(['podcast.episodes', 'pod-1']), isTrue);
      },
    );

    test('returns the cached value on a second call without re-fetching',
        () async {
      final http = CapturingClient()
        ..willReturn(json: [_episodeJson('e-3')])
        ..install();
      final provider = PlayableProvider();

      await provider.fetchForPodcast('pod-2');
      expect(http.requests, hasLength(1));

      // Second call: cache should serve it, no extra request.
      final cached = await provider.fetchForPodcast('pod-2');
      expect(http.requests, hasLength(1));
      expect(cached.single.id, 'e-3');
    });

    test(
      'forceRefresh clears the cache, re-fetches, and notifies listeners',
      () async {
        final http = CapturingClient()..install();
        final provider = PlayableProvider();

        // Seed the cache with the first response.
        http.willReturn(json: [_episodeJson('old-1')]);
        await provider.fetchForPodcast('pod-3');
        expect(http.requests, hasLength(1));

        var notifyCount = 0;
        provider.addListener(() => notifyCount++);

        // Force refresh → expect a new GET and a notification.
        http.willReturn(json: [_episodeJson('new-1'), _episodeJson('new-2')]);
        final refreshed =
            await provider.fetchForPodcast('pod-3', forceRefresh: true);

        expect(http.requests, hasLength(2));
        expect(refreshed.map((e) => e.id), ['new-1', 'new-2']);
        expect(notifyCount, 1);
      },
    );

    test(
      'getUpdates appends ?refresh=1 to the URL',
      () async {
        final http = CapturingClient()
          ..willReturn(json: [_episodeJson('e-4')])
          ..install();

        await PlayableProvider().fetchForPodcast(
          'pod-4',
          forceRefresh: true,
          getUpdates: true,
        );

        expect(
          http.requests.single.url,
          'https://koel.test/api/podcasts/pod-4/episodes?refresh=1',
        );
      },
    );

    test(
      'a non-forceful fetch does NOT notify listeners',
      () async {
        CapturingClient()
          ..willReturn(json: [_episodeJson('e-5')])
          ..install();
        final provider = PlayableProvider();

        var notifyCount = 0;
        provider.addListener(() => notifyCount++);

        await provider.fetchForPodcast('pod-5');

        expect(notifyCount, 0);
      },
    );
  });
}

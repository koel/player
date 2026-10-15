import 'package:app/exceptions/exceptions.dart';
import 'package:app/models/podcast.dart';
import 'package:app/providers/podcast_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/api_test_setup.dart';

Map<String, dynamic> _podcastJson({
  required String id,
  String title = 'A Show',
  bool favorite = false,
}) =>
    {
      'id': id,
      'title': title,
      'url': 'https://example.com/feed.xml',
      'link': 'https://example.com',
      'description': 'desc',
      'author': 'Author',
      'image': 'https://example.com/img.jpg',
      'subscribed_at': '2026-01-01T00:00:00Z',
      'last_played_at': '2026-01-02T00:00:00Z',
      'state': {'progresses': {}},
      'favorite': favorite,
    };

void main() {
  setUpAll(initApiTestEnvironment);
  setUp(setUpApiTest);
  tearDown(tearDownApiTest);

  group('PodcastProvider.toggleFavorite', () {
    test('flips optimistically, posts the right body, persists on 200',
        () async {
      final http = CapturingClient()..install();

      final podcast = Podcast.fake(id: 'p-1', favorite: false);
      final provider = PodcastProvider();

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.toggleFavorite(podcast);

      final req = http.requests.single;
      expect(req.method, 'POST');
      expect(req.url, 'https://koel.test/api/favorites/toggle');
      expect(req.jsonBody, {'type': 'podcast', 'id': 'p-1'});

      expect(podcast.favorite, isTrue);
      expect(notifyCount, 1);
    });

    test('rolls back, notifies again, and rethrows on failure', () async {
      final http = CapturingClient()..willReturn(status: 500)..install();

      final podcast = Podcast.fake(id: 'p-2', favorite: true);
      final provider = PodcastProvider();

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await expectLater(
        provider.toggleFavorite(podcast),
        throwsA(isA<HttpResponseException>()),
      );

      expect(podcast.favorite, isTrue);
      expect(http.requests, hasLength(1));
      expect(notifyCount, 2);
    });
  });

  group('PodcastProvider.unsubscribePodcast', () {
    test(
      'optimistically removes from list, then DELETEs and stays removed '
      'on success',
      () async {
        final http = CapturingClient()..install();
        final provider = PodcastProvider();

        // Seed via add().
        http.willReturn(json: _podcastJson(id: 'p-3'));
        final podcast = await provider.add(url: 'https://feed.xml');
        expect(provider.podcasts, [podcast]);

        http.requests.clear();
        http.willReturn();

        var notifyCount = 0;
        provider.addListener(() => notifyCount++);

        await provider.unsubscribePodcast(podcast);

        expect(provider.podcasts, isEmpty);
        // One notify before the await (optimistic), none after on success.
        expect(notifyCount, 1);
        expect(http.requests, hasLength(1));
        final req = http.requests.single;
        expect(req.method, 'DELETE');
        expect(req.url, endsWith('/podcasts/p-3/subscriptions'));
      },
    );

    test(
      'restores the podcast and rethrows on a failed DELETE',
      () async {
        final http = CapturingClient()..install();
        final provider = PodcastProvider();

        http.willReturn(json: _podcastJson(id: 'p-4'));
        final podcast = await provider.add(url: 'https://feed.xml');

        http.requests.clear();
        http.willReturn(status: 500);

        var notifyCount = 0;
        provider.addListener(() => notifyCount++);

        await expectLater(
          provider.unsubscribePodcast(podcast),
          throwsA(isA<HttpResponseException>()),
        );

        expect(provider.podcasts, [podcast]);
        // Two notifies: optimistic remove, then restore.
        expect(notifyCount, 2);
      },
    );
  });

  group('PodcastProvider.add', () {
    test(
      'POSTs the URL, parses the resource, and appends it to the list',
      () async {
        final http = CapturingClient()
          ..willReturn(json: _podcastJson(id: 'p-5', title: 'Added'))
          ..install();
        final provider = PodcastProvider();

        var notifyCount = 0;
        provider.addListener(() => notifyCount++);

        final podcast = await provider.add(url: 'https://feed.xml');

        final req = http.requests.single;
        expect(req.method, 'POST');
        expect(req.url, 'https://koel.test/api/podcasts');
        expect(req.jsonBody, {'url': 'https://feed.xml'});

        expect(podcast.id, 'p-5');
        expect(podcast.title, 'Added');
        expect(provider.podcasts, [podcast]);
        expect(notifyCount, 1);
      },
    );
  });

  group('PodcastProvider.fetchAll', () {
    test('GETs /podcasts and replaces the in-memory list', () async {
      final http = CapturingClient()
        ..willReturn(json: [
          _podcastJson(id: 'p-6', title: 'One'),
          _podcastJson(id: 'p-7', title: 'Two'),
        ])
        ..install();
      final provider = PodcastProvider();

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.fetchAll();

      final req = http.requests.single;
      expect(req.method, 'GET');
      expect(req.url, 'https://koel.test/api/podcasts');
      expect(provider.podcasts.map((p) => p.id), ['p-6', 'p-7']);
      expect(notifyCount, 1);
    });
  });
}

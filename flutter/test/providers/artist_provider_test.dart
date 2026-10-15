import 'package:app/exceptions/exceptions.dart';
import 'package:app/models/artist.dart';
import 'package:app/providers/artist_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/api_test_setup.dart';

void main() {
  setUpAll(initApiTestEnvironment);
  setUp(setUpApiTest);
  tearDown(tearDownApiTest);

  group('ArtistProvider.toggleFavorite', () {
    test('flips optimistically, posts the right body, persists on 200',
        () async {
      final http = CapturingClient()..install();

      final artist = Artist.fake(id: 9, favorite: false);
      final provider = ArtistProvider();

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.toggleFavorite(artist);

      final req = http.requests.single;
      expect(req.method, 'POST');
      expect(req.url, 'https://koel.test/api/favorites/toggle');
      expect(req.jsonBody, {'type': 'artist', 'id': 9});

      expect(artist.favorite, isTrue);
      expect(notifyCount, 1);
    });

    test('rolls back, notifies again, and rethrows on failure', () async {
      final http = CapturingClient()..willReturn(status: 500)..install();

      final artist = Artist.fake(id: 10, favorite: true);
      final provider = ArtistProvider();

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await expectLater(
        provider.toggleFavorite(artist),
        throwsA(isA<HttpResponseException>()),
      );

      expect(artist.favorite, isTrue);
      expect(http.requests, hasLength(1));
      expect(notifyCount, 2);
    });
  });

  group('ArtistProvider.update', () {
    test('PUTs the new name and merges the server response', () async {
      final http = CapturingClient()
        ..willReturn(json: {'name': 'Renamed'})
        ..install();

      final artist = Artist.fake(id: 11)..name = 'Old';
      final provider = ArtistProvider();

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.update(artist, name: 'Renamed');

      final req = http.requests.single;
      expect(req.method, 'PUT');
      expect(req.url, 'https://koel.test/api/artists/11');
      expect(req.jsonBody, {'name': 'Renamed'});

      expect(artist.name, 'Renamed');
      expect(notifyCount, 1);
    });
  });
}

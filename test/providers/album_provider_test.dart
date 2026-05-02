import 'package:app/exceptions/exceptions.dart';
import 'package:app/models/album.dart';
import 'package:app/providers/album_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/api_test_setup.dart';

void main() {
  setUpAll(initApiTestEnvironment);
  setUp(setUpApiTest);
  tearDown(tearDownApiTest);

  group('AlbumProvider.toggleFavorite', () {
    test('flips optimistically, posts the right body, persists on 200',
        () async {
      final http = CapturingClient()..install();

      final album = Album.fake(id: 7, favorite: false);
      final provider = AlbumProvider();

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.toggleFavorite(album);

      // Single request, expected URL/method/body.
      expect(http.requests, hasLength(1));
      final req = http.requests.single;
      expect(req.method, 'POST');
      expect(req.url, 'https://koel.test/api/favorites/toggle');
      expect(req.jsonBody, {'type': 'album', 'id': 7});

      // Optimistic flip is preserved on success.
      expect(album.favorite, isTrue);
      // One notify before the await, none after on success.
      expect(notifyCount, 1);
    });

    test('rolls back, notifies again, and rethrows on failure', () async {
      CapturingClient()..willReturn(status: 500)..install();

      final album = Album.fake(id: 8, favorite: true);
      final provider = AlbumProvider();

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await expectLater(
        provider.toggleFavorite(album),
        throwsA(isA<HttpResponseException>()),
      );

      // The optimistic flip was reverted.
      expect(album.favorite, isTrue);
      // Two notifies: one after the optimistic flip, one after the
      // rollback.
      expect(notifyCount, 2);
    });
  });

  group('AlbumProvider.update', () {
    test('PUTs the new fields and merges the server response', () async {
      final http = CapturingClient()
        ..willReturn(json: {'name': 'New Name', 'year': '1969'})
        ..install();

      final album = Album.fake(id: 4)
        ..name = 'Old Name'
        ..year = 1965;
      final provider = AlbumProvider();

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.update(album, name: 'New Name', year: 1969);

      final req = http.requests.single;
      expect(req.method, 'PUT');
      expect(req.url, 'https://koel.test/api/albums/4');
      expect(req.jsonBody, {'name': 'New Name', 'year': 1969});

      // Server response is the source of truth for the merged values.
      expect(album.name, 'New Name');
      expect(album.year, 1969);
      expect(notifyCount, 1);
    });

    test('treats a null year in the response as null on the model',
        () async {
      CapturingClient()
        ..willReturn(json: {'name': 'No Year', 'year': null})
        ..install();

      final album = Album.fake(id: 5)
        ..name = 'X'
        ..year = 2000;

      await AlbumProvider().update(album, name: 'No Year', year: null);

      expect(album.year, isNull);
    });
  });
}

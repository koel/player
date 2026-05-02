import 'package:app/exceptions/exceptions.dart';
import 'package:app/models/radio_station.dart';
import 'package:app/providers/radio_station_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/api_test_setup.dart';

void main() {
  setUpAll(initApiTestEnvironment);
  setUp(setUpApiTest);
  tearDown(tearDownApiTest);

  group('RadioStationProvider.toggleFavorite', () {
    test('flips optimistically, posts the right body, persists on 200',
        () async {
      final http = CapturingClient()..install();

      final station = RadioStation.fake(id: 's-1', favorite: false);
      final provider = RadioStationProvider();

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.toggleFavorite(station);

      final req = http.requests.single;
      expect(req.method, 'POST');
      expect(req.url, 'https://koel.test/api/favorites/toggle');
      expect(req.jsonBody, {'type': 'radio-station', 'id': 's-1'});

      expect(station.favorite, isTrue);
      expect(notifyCount, 1);
    });

    test('rolls back, notifies again, and rethrows on failure', () async {
      final http = CapturingClient()..willReturn(status: 500)..install();

      final station = RadioStation.fake(id: 's-2', favorite: true);
      final provider = RadioStationProvider();

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await expectLater(
        provider.toggleFavorite(station),
        throwsA(isA<HttpResponseException>()),
      );

      expect(station.favorite, isTrue);
      expect(http.requests, hasLength(1));
      expect(notifyCount, 2);
    });
  });

  group('RadioStationProvider.create', () {
    test(
      'POSTs the new fields, parses the response and appends to the list',
      () async {
        final http = CapturingClient()
          ..willReturn(json: {
            'id': 'new-1',
            'name': 'Jazz FM',
            'url': 'https://stream.example.com/jazz',
            'is_public': true,
            'description': 'Smooth jazz',
            'permissions': {'edit': true, 'delete': true},
          })
          ..install();

        final provider = RadioStationProvider();
        var notifyCount = 0;
        provider.addListener(() => notifyCount++);

        final created = await provider.create(
          name: 'Jazz FM',
          url: 'https://stream.example.com/jazz',
          description: 'Smooth jazz',
          isPublic: true,
        );

        final req = http.requests.single;
        expect(req.method, 'POST');
        expect(req.url, 'https://koel.test/api/radio/stations');
        expect(req.jsonBody, {
          'name': 'Jazz FM',
          'url': 'https://stream.example.com/jazz',
          'is_public': true,
          'description': 'Smooth jazz',
        });

        expect(created.id, 'new-1');
        expect(created.canEdit, isTrue);
        expect(provider.stations, [created]);
        expect(notifyCount, 1);
      },
    );

    test('omits description from the body when it is null or empty',
        () async {
      final http = CapturingClient()
        ..willReturn(json: {
          'id': 'new-2',
          'name': 'No Desc FM',
          'url': 'https://stream.example.com/x',
          'is_public': false,
        })
        ..install();

      await RadioStationProvider().create(
        name: 'No Desc FM',
        url: 'https://stream.example.com/x',
      );

      expect(http.requests.single.jsonBody, {
        'name': 'No Desc FM',
        'url': 'https://stream.example.com/x',
        'is_public': false,
      });
    });
  });

  group('RadioStationProvider.update', () {
    test('PUTs the new fields and writes them locally', () async {
      final http = CapturingClient()..install();

      final station = RadioStation.fake(id: 's-3')
        ..name = 'Old'
        ..url = 'https://old/'
        ..description = null
        ..isPublic = false;
      final provider = RadioStationProvider();

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.update(
        station,
        name: 'New',
        url: 'https://new/',
        description: 'desc',
        isPublic: true,
      );

      final req = http.requests.single;
      expect(req.method, 'PUT');
      expect(req.url, 'https://koel.test/api/radio/stations/s-3');
      expect(req.jsonBody, {
        'name': 'New',
        'url': 'https://new/',
        'description': 'desc',
        'is_public': true,
      });

      expect(station.name, 'New');
      expect(station.url, 'https://new/');
      expect(station.description, 'desc');
      expect(station.isPublic, isTrue);
      expect(notifyCount, 1);
    });

    test('serialises a null description as an empty string', () async {
      final http = CapturingClient()..install();
      final station = RadioStation.fake(id: 's-4');

      await RadioStationProvider().update(
        station,
        name: 'Same',
        url: station.url,
        description: null,
      );

      expect(http.requests.single.jsonBody!['description'], '');
    });
  });

  group('RadioStationProvider.remove', () {
    test(
      'optimistically drops the station, notifies, and fires a DELETE',
      () async {
        final http = CapturingClient()..install();

        final provider = RadioStationProvider();
        // Seed the list via create() — the provider doesn't expose a
        // public way to inject a station otherwise.
        http.willReturn(json: {
          'id': 's-5',
          'name': 'Stationy',
          'url': 'https://stream/',
          'is_public': false,
        });
        final station = await provider.create(
          name: 'Stationy',
          url: 'https://stream/',
        );
        expect(provider.stations, [station]);

        // Reset for the actual remove call.
        http.requests.clear();
        http.willReturn();

        var notifyCount = 0;
        provider.addListener(() => notifyCount++);

        await provider.remove(station);

        // Local list updated synchronously.
        expect(provider.stations, isEmpty);
        expect(notifyCount, 1);

        // The DELETE is fire-and-forget — drain the event queue so the
        // captured client gets a chance to record it.
        await Future<void>.delayed(Duration.zero);

        expect(http.requests, hasLength(1));
        final req = http.requests.single;
        expect(req.method, 'DELETE');
        expect(req.url, endsWith('/radio/stations/s-5'));
      },
    );
  });
}

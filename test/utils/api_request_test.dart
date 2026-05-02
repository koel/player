import 'dart:convert';

import 'package:app/exceptions/exceptions.dart';
import 'package:app/utils/api_request.dart' as api;
import 'package:app/utils/preferences.dart' as preferences;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/api_test_setup.dart';

void main() {
  setUpAll(initApiTestEnvironment);

  setUp(() {
    setUpApiTest();
    // override the helper's default token so the bearer-presence test
    // can assert against a known value.
    preferences.apiToken = 'tok-123';
  });

  tearDown(tearDownApiTest);

  group('request URL building', () {
    test('joins apiBaseUrl with the given path', () async {
      final http = CapturingClient()..install();

      await api.get('songs/42');

      expect(http.requests, hasLength(1));
      expect(
        http.requests.single.url,
        'https://koel.test/api/songs/42',
      );
    });
  });

  group('request method dispatch', () {
    test('GET sends the right method, no body', () async {
      final http = CapturingClient()..install();

      await api.get('albums');
      expect(http.requests.single.method, 'GET');
      expect(http.requests.single.rawBody, isEmpty);
    });

    test('POST sends a JSON body', () async {
      final http = CapturingClient()..install();

      await api.post('favorites/toggle', data: {'type': 'album', 'id': 7});

      final req = http.requests.single;
      expect(req.method, 'POST');
      expect(req.jsonBody, {'type': 'album', 'id': 7});
    });

    test('PUT sends a JSON body', () async {
      final http = CapturingClient()..install();

      await api.put('artists/9', data: {'name': 'X'});

      final req = http.requests.single;
      expect(req.method, 'PUT');
      expect(req.jsonBody, {'name': 'X'});
    });

    test('PATCH sends a JSON body', () async {
      final http = CapturingClient()..install();

      await api.patch('songs/3', data: {'title': 'Y'});

      final req = http.requests.single;
      expect(req.method, 'PATCH');
      expect(req.jsonBody, {'title': 'Y'});
    });

    test('DELETE sends a JSON body when one is provided', () async {
      final http = CapturingClient()..install();

      await api.delete('queue/items', data: {'ids': [1, 2]});

      final req = http.requests.single;
      expect(req.method, 'DELETE');
      expect(req.jsonBody, {'ids': [1, 2]});
    });
  });

  group('request headers', () {
    test('sets JSON content-type, accept, version, and bearer', () async {
      final http = CapturingClient()..install();

      await api.get('me');

      final headers = http.requests.single.headers;
      expect(headers['content-type'], contains('application/json'));
      expect(headers['accept'], contains('application/json'));
      expect(headers['x-api-version'], 'v6');
      expect(headers['authorization'], 'Bearer tok-123');
    });

    test('omits the Authorization header when no token is set', () async {
      preferences.apiToken = null;
      final http = CapturingClient()..install();

      await api.get('login');

      expect(
        http.requests.single.headers.containsKey('authorization'),
        isFalse,
      );
    });
  });

  group('response handling', () {
    test('returns the decoded JSON on 2xx', () async {
      CapturingClient()
        ..willReturnRaw(body: jsonEncode({'hello': 'world'}))
        ..install();

      final result = await api.get('hello');
      expect(result, {'hello': 'world'});
    });

    test('returns null when 2xx body is not JSON', () async {
      CapturingClient()..willReturnRaw(body: 'not-json')..install();

      final result = await api.get('hello');
      expect(result, isNull);
    });

    test('throws HttpResponseException on non-2xx', () async {
      CapturingClient()
        ..willReturn(status: 422, json: {'message': 'nope'})
        ..install();

      expect(
        () => api.post('favorites/toggle', data: {}),
        throwsA(isA<HttpResponseException>()),
      );
    });
  });
}

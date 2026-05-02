import 'dart:convert';

import 'package:app/exceptions/exceptions.dart';
import 'package:app/utils/api_request.dart' as api;
import 'package:app/utils/preferences.dart' as preferences;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as Http;
import 'package:http/testing.dart';

class _CapturingClient {
  final MockClient client;
  final List<Http.Request> captured;
  _CapturingClient(this.client, this.captured);
}

/// Builds a [MockClient] that records every request it receives and
/// replies with [responseStatus] / [responseBody].
_CapturingClient _captureClient({
  int responseStatus = 200,
  String responseBody = '{}',
}) {
  final captured = <Http.Request>[];
  final client = MockClient((Http.Request request) async {
    captured.add(request);
    return Http.Response(responseBody, responseStatus);
  });
  return _CapturingClient(client, captured);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // GetStorage.init() pulls the docs dir via path_provider, which has
    // no plugin implementation in widget tests. Stub the channel so
    // GetStorage falls back to a writable location.
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => '.');
    await GetStorage.init('Preferences');
  });

  setUp(() {
    preferences.host = 'https://koel.test';
    preferences.apiToken = 'tok-123';
  });

  tearDown(() {
    preferences.host = null;
    preferences.apiToken = null;
    api.resetHttpClientForTesting();
  });

  group('request URL building', () {
    test('joins apiBaseUrl with the given path', () async {
      final mock = _captureClient();
      api.setHttpClientForTesting(mock.client);

      await api.get('songs/42');

      expect(mock.captured, hasLength(1));
      expect(
        mock.captured.single.url.toString(),
        'https://koel.test/api/songs/42',
      );
    });
  });

  group('request method dispatch', () {
    test('GET sends the right method, no body', () async {
      final mock = _captureClient();
      api.setHttpClientForTesting(mock.client);

      await api.get('albums');
      expect(mock.captured.single.method, 'GET');
      expect(mock.captured.single.body, isEmpty);
    });

    test('POST sends a JSON body', () async {
      final mock = _captureClient();
      api.setHttpClientForTesting(mock.client);

      await api.post('favorites/toggle', data: {'type': 'album', 'id': 7});

      final req = mock.captured.single;
      expect(req.method, 'POST');
      expect(json.decode(req.body), {'type': 'album', 'id': 7});
    });

    test('PUT sends a JSON body', () async {
      final mock = _captureClient();
      api.setHttpClientForTesting(mock.client);

      await api.put('artists/9', data: {'name': 'X'});

      final req = mock.captured.single;
      expect(req.method, 'PUT');
      expect(json.decode(req.body), {'name': 'X'});
    });

    test('PATCH sends a JSON body', () async {
      final mock = _captureClient();
      api.setHttpClientForTesting(mock.client);

      await api.patch('songs/3', data: {'title': 'Y'});

      final req = mock.captured.single;
      expect(req.method, 'PATCH');
      expect(json.decode(req.body), {'title': 'Y'});
    });

    test('DELETE sends a JSON body when one is provided', () async {
      final mock = _captureClient();
      api.setHttpClientForTesting(mock.client);

      await api.delete('queue/items', data: {'ids': [1, 2]});

      final req = mock.captured.single;
      expect(req.method, 'DELETE');
      expect(json.decode(req.body), {'ids': [1, 2]});
    });
  });

  group('request headers', () {
    test('sets JSON content-type, accept, version, and bearer', () async {
      final mock = _captureClient();
      api.setHttpClientForTesting(mock.client);

      await api.get('me');

      final headers = mock.captured.single.headers;
      expect(headers['content-type'], contains('application/json'));
      expect(headers['accept'], contains('application/json'));
      expect(headers['x-api-version'], 'v6');
      expect(headers['authorization'], 'Bearer tok-123');
    });

    test('omits the Authorization header when no token is set', () async {
      preferences.apiToken = null;
      final mock = _captureClient();
      api.setHttpClientForTesting(mock.client);

      await api.get('login');

      expect(
        mock.captured.single.headers.containsKey('authorization'),
        isFalse,
      );
    });
  });

  group('response handling', () {
    test('returns the decoded JSON on 2xx', () async {
      final mock = _captureClient(responseBody: '{"hello":"world"}');
      api.setHttpClientForTesting(mock.client);

      final result = await api.get('hello');
      expect(result, {'hello': 'world'});
    });

    test('returns null when 2xx body is not JSON', () async {
      final mock = _captureClient(responseBody: 'not-json');
      api.setHttpClientForTesting(mock.client);

      final result = await api.get('hello');
      expect(result, isNull);
    });

    test('throws HttpResponseException on non-2xx', () async {
      final mock = _captureClient(
        responseStatus: 422,
        responseBody: '{"message":"nope"}',
      );
      api.setHttpClientForTesting(mock.client);

      expect(
        () => api.post('favorites/toggle', data: {}),
        throwsA(isA<HttpResponseException>()),
      );
    });
  });
}

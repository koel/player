import 'dart:convert';
import 'dart:io';

import 'package:app/utils/api_request.dart' as api;
import 'package:app/utils/preferences.dart' as preferences;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as Http;
import 'package:http/testing.dart';

/// One-time bring-up for any test that touches `api_request.dart`:
/// initialises `GetStorage` (which is needed by `preferences`) and
/// stubs the `path_provider` channel so it works in widget tests.
///
/// Each test isolate gets its own temp directory so the
/// `./Preferences.gs` file lock doesn't collide when several provider
/// test files run in parallel.
///
/// Call from `setUpAll`.
Future<void> initApiTestEnvironment() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final tmp = await Directory.systemTemp.createTemp('koel_test_');
  // GetStorage.init() pulls the docs dir via path_provider, which has
  // no plugin implementation in widget tests. Stub the channel so it
  // falls back to a writable location.
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async => tmp.path);
  await GetStorage.init('Preferences');
}

/// Sets stable values for the preferences the api_request layer reads.
/// Pair with [tearDownApiTest] to clear them again.
void setUpApiTest() {
  preferences.host = 'https://koel.test';
  preferences.apiToken = 'tok';
}

/// Resets the http client and clears preferences. Call from `tearDown`.
void tearDownApiTest() {
  preferences.host = null;
  preferences.apiToken = null;
  api.resetHttpClientForTesting();
}

/// Records every outgoing request and replies with a configurable
/// status / body. Each captured entry exposes the URL, method and
/// decoded JSON body for assertions.
class CapturingClient {
  final List<CapturedRequest> requests = [];
  int _status = 200;
  String _body = '{}';

  late final MockClient client = MockClient((request) async {
    final raw = request.body;
    requests.add(CapturedRequest(
      method: request.method,
      url: request.url.toString(),
      // Lowercase keys: http's internal request.headers is
      // case-insensitive, but a plain Map<String, String> copy isn't
      // — normalise so test lookups don't depend on the package's
      // storage casing.
      headers: {
        for (final entry in request.headers.entries)
          entry.key.toLowerCase(): entry.value,
      },
      rawBody: raw,
    ));
    return Http.Response(_body, _status);
  });

  /// Sets the response the next (and subsequent) requests will see.
  void willReturn({int status = 200, Object? json}) {
    _status = status;
    _body = json == null ? '' : jsonEncode(json);
  }

  /// Sets a status with a literal text body (use for non-JSON / 4xx /
  /// 5xx fixtures).
  void willReturnRaw({int status = 200, String body = ''}) {
    _status = status;
    _body = body;
  }

  /// Installs this client as the api_request module's active client.
  void install() => api.setHttpClientForTesting(client);
}

class CapturedRequest {
  final String method;
  final String url;
  final Map<String, String> headers;
  final String rawBody;

  CapturedRequest({
    required this.method,
    required this.url,
    required this.headers,
    required this.rawBody,
  });

  Map<String, dynamic>? get jsonBody {
    if (rawBody.isEmpty) return null;
    final decoded = jsonDecode(rawBody);
    return decoded is Map<String, dynamic> ? decoded : null;
  }
}

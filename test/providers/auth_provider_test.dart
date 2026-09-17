import 'package:app/exceptions/exceptions.dart';
import 'package:app/providers/auth_provider.dart';
import 'package:app/utils/preferences.dart' as preferences;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/api_test_setup.dart';

void main() {
  late AuthProvider auth;
  late CapturingClient client;

  setUpAll(() async => await initApiTestEnvironment());

  setUp(() {
    auth = AuthProvider();
    client = CapturingClient();
    client.install();
    setUpApiTest();
    preferences.apiToken = null;
    preferences.audioToken = null;
  });

  tearDown(tearDownApiTest);

  group('login', () {
    test('stores the composite token and returns null on a normal login',
        () async {
      client.willReturn(json: {'token': 'api-tok', 'audio-token': 'aud-tok'});

      final challenge = await auth.login(
        host: 'https://koel.test',
        email: 'user@koel.test',
        password: 'secret',
      );

      expect(challenge, isNull);
      expect(preferences.apiToken, 'api-tok');
      expect(preferences.audioToken, 'aud-tok');

      final request = client.requests.single;
      expect(request.url, 'https://koel.test/api/me');
      expect(request.method, 'POST');
      expect(request.jsonBody, {'email': 'user@koel.test', 'password': 'secret'});
    });

    test('returns a challenge and stores no token when 2FA is required',
        () async {
      client.willReturn(json: {'two_factor': true, 'login_token': 'lt-123'});

      final challenge = await auth.login(
        host: 'https://koel.test',
        email: 'user@koel.test',
        password: 'secret',
      );

      expect(challenge, isNotNull);
      expect(challenge!.loginToken, 'lt-123');
      expect(preferences.apiToken, isNull);
      expect(preferences.audioToken, isNull);
    });
  });

  group('completeTwoFactorChallenge', () {
    test('posts the login token and code, then stores the composite token',
        () async {
      client.willReturn(json: {'token': 'api-2fa', 'audio-token': 'aud-2fa'});

      await auth.completeTwoFactorChallenge(
        loginToken: 'lt-123',
        code: '123456',
      );

      expect(preferences.apiToken, 'api-2fa');
      expect(preferences.audioToken, 'aud-2fa');

      final request = client.requests.single;
      expect(request.url, 'https://koel.test/api/me/two-factor-challenge');
      expect(request.method, 'POST');
      expect(request.jsonBody, {'login_token': 'lt-123', 'code': '123456'});
    });

    test('propagates a 401 for an invalid code', () async {
      client.willReturnRaw(status: 401, body: 'Invalid credentials');

      await expectLater(
        auth.completeTwoFactorChallenge(loginToken: 'lt-123', code: 'wrong'),
        throwsA(isA<HttpResponseException>()),
      );

      expect(preferences.apiToken, isNull);
    });
  });

  group('tryGetAuthUser', () {
    test('stores the signed-in user and announces the login', () async {
      preferences.apiToken = 'tok';
      client.willReturn(json: {
        'id': 'user-1',
        'name': 'Jane',
        'email': 'jane@koel.test',
      });
      final announcedUsers = <String>[];
      final subscription = AuthProvider.userLoggedInStream
          .listen((user) => announcedUsers.add(user.name));
      addTearDown(subscription.cancel);

      final user = await auth.tryGetAuthUser();
      await Future<void>.delayed(Duration.zero);

      expect(user!.name, 'Jane');
      expect(auth.authUser.name, 'Jane');
      expect(announcedUsers, ['Jane']);
    });

    test('returns null without a request when there is no token', () async {
      expect(await auth.tryGetAuthUser(), isNull);
      expect(client.requests, isEmpty);
    });
  });

  group('refreshAuthUser', () {
    test('replaces the signed-in user with the latest one from the server',
        () async {
      client.willReturn(json: {
        'id': 'user-1',
        'name': 'Jane',
        'email': 'jane@koel.test',
      });
      await auth.refreshAuthUser();

      client.willReturn(json: {
        'id': 'user-1',
        'name': 'Jane Doe',
        'email': 'jane@koel.test',
      });
      final user = await auth.refreshAuthUser();

      expect(user.name, 'Jane Doe');
      expect(auth.authUser.name, 'Jane Doe');
      expect(client.requests.last.url, 'https://koel.test/api/me');
      expect(client.requests.last.method, 'GET');
    });

    test('does not announce a login', () async {
      client.willReturn(json: {
        'id': 'user-1',
        'name': 'Jane',
        'email': 'jane@koel.test',
      });
      var loginAnnouncements = 0;
      final subscription =
          AuthProvider.userLoggedInStream.listen((_) => loginAnnouncements++);
      addTearDown(subscription.cancel);

      await auth.refreshAuthUser();
      await Future<void>.delayed(Duration.zero);

      expect(loginAnnouncements, 0);
    });
  });
}

import 'dart:async';

import 'package:app/app_state.dart';
import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/utils/api_request.dart';
import 'package:app/utils/preferences.dart' as preferences;

class AuthProvider with StreamSubscriber {
  late User _authUser;

  User get authUser => _authUser;

  static final _userLoggedIn = StreamController<User>.broadcast();
  static final userLoggedInStream = _userLoggedIn.stream;

  static final _userLoggedOut = StreamController<void>.broadcast();
  static final userLoggedOutStream = _userLoggedOut.stream;

  AuthProvider() {
    subscribe(userLoggedOutStream.listen((_) {
      preferences.apiToken = null;
      preferences.audioToken = null;
      AppState.clear();
    }));
  }

  /// Returns a [TwoFactorChallenge] when the server requires a second factor,
  /// or `null` when the credentials alone completed the login.
  Future<TwoFactorChallenge?> login(
      {required String host,
      required String email,
      required String password}) async {
    preferences.host = host;

    final loginData = <String, String>{
      'email': email,
      'password': password,
    };

    final response = await post('me', data: loginData);

    if (response['two_factor'] == true) {
      return TwoFactorChallenge(loginToken: response['login_token']);
    }

    _storeCompositeToken(response);
    return null;
  }

  Future<void> completeTwoFactorChallenge({
    required String loginToken,
    required String code,
  }) async {
    final response = await post('me/two-factor-challenge', data: {
      'login_token': loginToken,
      'code': code,
    });

    _storeCompositeToken(response);
  }

  Future<void> loginWithOneTimeToken({
    required String host,
    required String token,
  }) async {
    preferences.host = host;

    final loginData = <String, String>{
      'token': token,
    };

    _storeCompositeToken(await post('me/otp', data: loginData));
  }

  void _storeCompositeToken(dynamic response) {
    preferences.apiToken = response['token'];
    preferences.audioToken = response['audio-token'];
  }

  void setAuthUser(User user) => _authUser = user;

  Future<User?> tryGetAuthUser() async {
    if (preferences.apiToken == null) {
      return null;
    }

    var user = User.fromJson(await get('me'));

    this.setAuthUser(user);
    _userLoggedIn.add(user);

    return authUser;
  }

  Future<void> logout() async {
    try {
      await delete('me');
    } catch (_) {}

    _userLoggedOut.add(null);
  }
}

class TwoFactorChallenge {
  final String loginToken;

  const TwoFactorChallenge({required this.loginToken});
}

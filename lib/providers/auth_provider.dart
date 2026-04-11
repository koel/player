import 'dart:async';

import 'package:app/app_state.dart';
import 'package:app/constants/constants.dart';
import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/utils/api_request.dart';
import 'package:app/utils/preferences.dart' as preferences;
import 'package:google_sign_in/google_sign_in.dart';

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

  Future<void> login(
      {required String host,
      required String email,
      required String password}) async {
    preferences.host = host;

    final loginData = <String, String>{
      'email': email,
      'password': password,
    };

    final response = await post('me', data: loginData);
    preferences.apiToken = response['token'];
    preferences.audioToken = response['audio-token'];
  }

  Future<void> loginWithOneTimeToken({
    required String host,
    required String token,
  }) async {
    preferences.host = host;

    final loginData = <String, String>{
      'token': token,
    };

    final response = await post('me/otp', data: loginData);
    preferences.apiToken = response['token'];
    preferences.audioToken = response['audio-token'];
  }

  /// Returns null on success (tokens stored), or a Map with sso_user/legal_urls
  /// if consent is required for a new user.
  Future<Map<String, dynamic>?> loginWithGoogle({required String host}) async {
    final googleSignIn = GoogleSignIn(
      // Web OAuth Client ID used as the audience when validating the id_token server-side.
      serverClientId: AppStrings.googleServerClientId,
    );

    final account = await googleSignIn.signIn();
    if (account == null) throw Exception('Google Sign-In cancelled');

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) throw Exception('No ID token received');

    preferences.host = host;

    final response = await post('me/google', data: {'id_token': idToken});

    if (response == null) throw Exception('Empty response from server');

    if (response['requires_consent'] == true) {
      return response;
    }

    preferences.apiToken = response['token'];
    preferences.audioToken = response['audio-token'];
    return null;
  }

  Future<void> completeGoogleConsent({
    required Map<String, dynamic> ssoUser,
  }) async {
    final response = await post('me/google/consent', data: {
      'sso_user': ssoUser,
      'terms_accepted': true,
      'privacy_accepted': true,
      'age_verified': true,
    });

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

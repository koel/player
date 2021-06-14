import 'package:app/utils/api_request.dart';
import 'package:app/utils/preferences.dart';
import 'package:flutter/foundation.dart';

enum Status { NotLoggedIn, LoggedIn, Authenticating, LoggedOut }

class AuthProvider with ChangeNotifier {
  Status _loggedInStatus = Status.NotLoggedIn;

  Status get loggedInStatus => _loggedInStatus;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final Map<String, dynamic> loginData = {
      'email': email,
      'password': password,
    };

    _loggedInStatus = Status.Authenticating;
    notifyListeners();

    try {
      final responseData = await ApiRequest.post('me', data: loginData);
      await (new Preferences()).setApiToken(responseData['token']);

      _loggedInStatus = Status.LoggedIn;
      notifyListeners();

      return {
        'status': true,
        'message': 'Successful',
        'token': responseData['token']
      };
    } catch (err) {
      _loggedInStatus = Status.NotLoggedIn;
      notifyListeners();
      print(err);

      return {
        'status': false,
      };
    }
  }
}

import 'package:app/utils/api_request.dart';
import 'package:app/utils/preferences.dart';
import 'package:flutter/foundation.dart';

class AuthProvider with ChangeNotifier {
  Future<bool> login({required String email, required String password}) async {
    final Map<String, String> loginData = {
      'email': email,
      'password': password,
    };

    try {
      final responseData = await post('me', data: loginData);
      await setApiToken(responseData['token']);
      return true;
    } catch (err) {
      print(err);
      return false;
    }
  }
}

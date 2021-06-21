import 'package:app/models/user.dart';
import 'package:app/utils/api_request.dart';
import 'package:app/utils/preferences.dart';
import 'package:flutter/foundation.dart';

class UserProvider with ChangeNotifier {
  late User _authUser;

  User get authUser => _authUser;

  void setAuthUser(User user) {
    _authUser = user;
    notifyListeners();
  }

  Future<User?> tryGetAuthUser() async {
    if (await apiToken == null) {
      return null;
    }

    final Map<String, dynamic> userData = await ApiRequest.get('me');
    this.setAuthUser(User.fromJson(userData));

    return authUser;
  }
}

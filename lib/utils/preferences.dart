import 'package:shared_preferences/shared_preferences.dart';

SharedPreferences? _sharedPref;

Future<SharedPreferences> get sharedPef async {
  if (_sharedPref == null) {
    _sharedPref = await SharedPreferences.getInstance();
  }

  return _sharedPref!;
}

Future<void> setHostUrl(String url) async {
  (await sharedPef).setString('hostUrl', url);
}

Future<String?> get hostUrl async {
  return (await sharedPef).getString('hostUrl');
}

Future<String?> get apiBaseUrl async {
  return "${await hostUrl}/api";
}

Future<void> setApiToken(String token) async {
  (await sharedPef).setString('apiToken', token);
}

Future<String?> get apiToken async {
  return (await sharedPef).getString('apiToken');
}

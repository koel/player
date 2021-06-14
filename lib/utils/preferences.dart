import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  Future<SharedPreferences> getPrefInstance() async {
    return await SharedPreferences.getInstance();
  }

  Future<void> setHostUrl(String url) async {
    (await getPrefInstance()).setString('hostUrl', url);
  }

  Future<String> getApiBaseUrl() async {
    return (await getPrefInstance()).getString('hostUrl')! + '/api';
  }

  Future<void> setApiToken(String token) async {
    (await getPrefInstance()).setString('apiToken', token);
  }

  Future<String?> getApiToken() async {
    return (await getPrefInstance()).getString('apiToken');
  }
}

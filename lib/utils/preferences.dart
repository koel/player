import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:shared_preferences/shared_preferences.dart';

SharedPreferences? _sharedPref;

Future<SharedPreferences> get sharedPref async {
  if (_sharedPref == null) {
    _sharedPref = await SharedPreferences.getInstance();
  }

  return _sharedPref!;
}

Future<void> setHostUrl(String url) async =>
    (await sharedPref).setString('hostUrl', url);

Future<String?> get hostUrl async => (await sharedPref).getString('hostUrl');

Future<String?> get apiBaseUrl async => '${await hostUrl}/api';

Future<void> setApiToken(String token) async =>
    (await sharedPref).setString('apiToken', token);

Future<void> removeApiToken() async => (await sharedPref).remove('apiToken');

Future<void> setUserEmail(String token) async =>
    (await sharedPref).setString('email', token);

Future<String?> get userEmail async => (await sharedPref).getString('email');

Future<String?> get apiToken async => (await sharedPref).getString('apiToken');

Future<void> setLoopMode(LoopMode mode) async {
  (await sharedPref).setString('loopMode', EnumToString.convertToString(mode));
}

Future<LoopMode> get loopMode async {
  String? loopModeAsString = (await sharedPref).getString('loopMode');

  return EnumToString.fromString(LoopMode.values, loopModeAsString ?? '') ??
      LoopMode.none;
}

Future<void> setVolume(double volume) async =>
    (await sharedPref).setDouble('volume', volume);

Future<double> get volume async =>
    (await sharedPref).getDouble('volume') ?? 0.7;

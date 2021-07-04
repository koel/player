import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:shared_preferences/shared_preferences.dart';

SharedPreferences? _sharedPref;

Future<SharedPreferences> get sharedPef async {
  if (_sharedPref == null) {
    _sharedPref = await SharedPreferences.getInstance();
  }

  return _sharedPref!;
}

Future<void> setHostUrl(String url) async =>
    (await sharedPef).setString('hostUrl', url);

Future<String?> get hostUrl async => (await sharedPef).getString('hostUrl');

Future<String?> get apiBaseUrl async => '${await hostUrl}/api';

Future<void> setApiToken(String token) async =>
    (await sharedPef).setString('apiToken', token);

Future<void> setUserEmail(String token) async =>
    (await sharedPef).setString('email', token);

Future<String?> get userEmail async => (await sharedPef).getString('email');

Future<String?> get apiToken async => (await sharedPef).getString('apiToken');

Future<void> setLoopMode(LoopMode mode) async =>
    (await sharedPef).setString('loopMode', EnumToString.convertToString(mode));

Future<LoopMode> get loopMode async {
  String? loopModeAsString = (await sharedPef).getString('loopMode');

  return EnumToString.fromString(LoopMode.values, loopModeAsString ?? '') ??
      LoopMode.none;
}

Future<void> setVolume(double volume) async =>
    (await sharedPef).setDouble('volume', volume);

Future<double> get volume async => (await sharedPef).getDouble('volume') ?? 0.7;

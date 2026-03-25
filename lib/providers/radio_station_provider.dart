import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/auth_provider.dart';
import 'package:app/utils/api_request.dart';
import 'package:flutter/foundation.dart';

class RadioStationProvider with ChangeNotifier, StreamSubscriber {
  var _stations = <RadioStation>[];

  List<RadioStation> get stations => _stations.toList();

  RadioStationProvider() {
    subscribe(AuthProvider.userLoggedOutStream.listen((_) {
      _stations.clear();
      notifyListeners();
    }));
  }

  Future<void> fetchAll() async {
    final res = await get('radio/stations');
    _stations = (res as List)
        .map<RadioStation>((j) => RadioStation.fromJson(j))
        .toList();
    notifyListeners();
  }

  Future<RadioStation> create({
    required String name,
    required String url,
    String? description,
    bool isPublic = false,
  }) async {
    final json = await post('radio/stations', data: {
      'name': name,
      'url': url,
      'is_public': isPublic,
      if (description != null && description.isNotEmpty)
        'description': description,
    });

    final station = RadioStation.fromJson(json);
    _stations.add(station);
    notifyListeners();
    return station;
  }

  Future<void> update(
    RadioStation station, {
    required String name,
    required String url,
    String? description,
    bool isPublic = false,
  }) async {
    await put('radio/stations/${station.id}', data: {
      'name': name,
      'url': url,
      'description': description ?? '',
      'is_public': isPublic,
    });

    station
      ..name = name
      ..url = url
      ..description = description
      ..isPublic = isPublic;

    notifyListeners();
  }

  Future<void> remove(RadioStation station) async {
    delete('radio/stations/${station.id}');
    _stations.remove(station);
    notifyListeners();
  }

  Future<Map<String, dynamic>> getNowPlaying(RadioStation station) async {
    return await get('radio/stations/${station.id}/now-playing');
  }
}

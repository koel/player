import 'dart:convert';

import 'package:app/models/album.dart';
import 'package:app/models/artist.dart';
import 'package:app/models/podcast.dart';
import 'package:app/models/radio_station.dart';
import 'package:app/providers/album_provider.dart';
import 'package:app/providers/artist_provider.dart';
import 'package:app/providers/podcast_provider.dart';
import 'package:app/providers/radio_station_provider.dart';
import 'package:app/utils/api_request.dart' as api;
import 'package:app/utils/preferences.dart' as preferences;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as Http;
import 'package:http/testing.dart';

/// Captures every outgoing request's URL and decoded JSON body so test
/// cases can assert exact request shape — locking in the singular
/// `type` strings the koel server's FavoriteableType enum requires.
class _Recorder {
  final List<String> urls = [];
  final List<Map<String, dynamic>> bodies = [];

  late final MockClient client = MockClient((request) async {
    urls.add(request.url.toString());
    bodies.add(json.decode(request.body) as Map<String, dynamic>);
    return Http.Response('{}', 200);
  });
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => '.');
    await GetStorage.init('Preferences');
  });

  setUp(() {
    preferences.host = 'https://koel.test';
    preferences.apiToken = 'tok';
  });

  tearDown(() {
    preferences.host = null;
    preferences.apiToken = null;
    api.resetHttpClientForTesting();
  });

  test('AlbumProvider.toggleFavorite POSTs type:album (singular)', () async {
    final recorder = _Recorder();
    api.setHttpClientForTesting(recorder.client);

    final album = Album.fake(id: 7);
    await AlbumProvider().toggleFavorite(album);

    expect(recorder.urls, ['https://koel.test/api/favorites/toggle']);
    expect(recorder.bodies, [
      {'type': 'album', 'id': 7},
    ]);
  });

  test('ArtistProvider.toggleFavorite POSTs type:artist (singular)',
      () async {
    final recorder = _Recorder();
    api.setHttpClientForTesting(recorder.client);

    final artist = Artist.fake(id: 9);
    await ArtistProvider().toggleFavorite(artist);

    expect(recorder.bodies, [
      {'type': 'artist', 'id': 9},
    ]);
  });

  test(
    'RadioStationProvider.toggleFavorite POSTs type:radio-station '
    '(singular, hyphenated)',
    () async {
      final recorder = _Recorder();
      api.setHttpClientForTesting(recorder.client);

      final station = RadioStation.fake(id: 's1');
      await RadioStationProvider().toggleFavorite(station);

      expect(recorder.bodies, [
        {'type': 'radio-station', 'id': 's1'},
      ]);
    },
  );

  test('PodcastProvider.toggleFavorite POSTs type:podcast (singular)',
      () async {
    final recorder = _Recorder();
    api.setHttpClientForTesting(recorder.client);

    final podcast = Podcast.fake(id: 'p1');
    await PodcastProvider().toggleFavorite(podcast);

    expect(recorder.bodies, [
      {'type': 'podcast', 'id': 'p1'},
    ]);
  });
}

import 'package:app/models/song.dart';
import 'package:app/providers/album_provider.dart';
import 'package:app/providers/artist_provider.dart';
import 'package:app/providers/overview_provider.dart';
import 'package:app/providers/playable_provider.dart';
import 'package:app/providers/recently_played_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/api_test_setup.dart';

void main() {
  late OverviewProvider overview;
  late CapturingClient client;
  var _seq = 0;

  List<Map<String, dynamic>> songs(int count) =>
      List.generate(count, (_) => Song.fake().toJson());

  List<Map<String, dynamic>> albums(int count) => List.generate(count, (_) {
        final id = 'album-${_seq++}';
        return {
          'id': id,
          'name': 'Album $id',
          'cover': null,
          'artist_id': 'artist-$id',
          'artist_name': 'Artist $id',
          'year': null,
        };
      });

  List<Map<String, dynamic>> artists(int count) => List.generate(count, (_) {
        final id = 'artist-${_seq++}';
        return {'id': id, 'name': 'Artist $id', 'image': null};
      });

  setUpAll(() async => await initApiTestEnvironment());

  setUp(() {
    _seq = 0;
    final playableProvider = PlayableProvider();
    overview = OverviewProvider(
      playableProvider: playableProvider,
      albumProvider: AlbumProvider(),
      artistProvider: ArtistProvider(),
      recentlyPlayedProvider:
          RecentlyPlayedProvider(playableProvider: playableProvider),
    );
    client = CapturingClient();
    client.install();
    setUpApiTest();
  });

  tearDown(tearDownApiTest);

  test('refresh populates every overview section', () async {
    client.willReturn(json: {
      'most_played_songs': songs(3),
      'recently_added_songs': songs(2),
      'recently_played_songs': songs(4),
      'least_played_songs': songs(1),
      'random_songs': songs(5),
      'similar_songs': songs(6),
      'most_played_albums': albums(3),
      'recently_added_albums': albums(2),
      'random_albums': albums(4),
      'most_played_artists': artists(3),
      'recently_added_artists': artists(2),
      'random_artists': artists(4),
    });

    await overview.refresh();

    expect(overview.mostPlayedSongs, hasLength(3));
    expect(overview.recentlyAddedSongs, hasLength(2));
    expect(overview.recentlyPlayedSongs, hasLength(4));
    expect(overview.leastPlayedSongs, hasLength(1));
    expect(overview.randomSongs, hasLength(5));
    expect(overview.similarSongs, hasLength(6));
    expect(overview.mostPlayedAlbums, hasLength(3));
    expect(overview.recentlyAddedAlbums, hasLength(2));
    expect(overview.randomAlbums, hasLength(4));
    expect(overview.mostPlayedArtists, hasLength(3));
    expect(overview.recentlyAddedArtists, hasLength(2));
    expect(overview.randomArtists, hasLength(4));
  });

  test('refresh leaves sections empty when an older API omits them', () async {
    client.willReturn(json: {
      'most_played_songs': songs(2),
      'recently_played_songs': songs(1),
      'most_played_albums': albums(2),
      'most_played_artists': artists(2),
    });

    await overview.refresh();

    expect(overview.mostPlayedSongs, hasLength(2));
    expect(overview.recentlyPlayedSongs, hasLength(1));
    expect(overview.mostPlayedAlbums, hasLength(2));
    expect(overview.mostPlayedArtists, hasLength(2));

    expect(overview.recentlyAddedSongs, isEmpty);
    expect(overview.leastPlayedSongs, isEmpty);
    expect(overview.randomSongs, isEmpty);
    expect(overview.similarSongs, isEmpty);
    expect(overview.recentlyAddedAlbums, isEmpty);
    expect(overview.randomAlbums, isEmpty);
    expect(overview.recentlyAddedArtists, isEmpty);
    expect(overview.randomArtists, isEmpty);

    expect(overview.isEmpty, isFalse);
  });

  test('isEmpty is true when the API returns nothing', () async {
    client.willReturn(json: {});

    await overview.refresh();

    expect(overview.isEmpty, isTrue);
  });
}

import 'package:app/models/album.dart';
import 'package:app/models/artist.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/album_provider.dart';
import 'package:app/providers/artist_provider.dart';
import 'package:app/providers/playable_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/api_test_setup.dart';

PlayableProvider _seedPlayables(List<Song> songs) {
  final provider = PlayableProvider();
  provider.syncWithVault(songs);
  return provider;
}

Future<void> _flushMicrotasks() => Future<void>.delayed(Duration.zero);

void main() {
  setUpAll(initApiTestEnvironment);
  setUp(setUpApiTest);
  tearDown(tearDownApiTest);

  group('AlbumProvider rename → PlayableProvider', () {
    test(
      'songs sharing the renamed album get their albumName updated',
      (() async {
        CapturingClient()
          ..willReturn(json: {'name': 'New Album', 'year': null})
          ..install();

        final artist = Artist.fake();
        final album = Album.fake(id: 'a-1', artist: artist)..name = 'Old';
        final matching = Song.fake(album: album);
        final unrelated = Song.fake();
        final playables = _seedPlayables([matching, unrelated]);

        final albumProvider = AlbumProvider();
        var notifyCount = 0;
        playables.addListener(() => notifyCount++);

        await albumProvider.update(album, name: 'New Album');
        await _flushMicrotasks();

        expect(matching.albumName, 'New Album');
        expect(unrelated.albumName, isNot('New Album'));
        expect(notifyCount, greaterThanOrEqualTo(1));
      }),
    );

    test(
      'no propagation (and no notify) when the name did not change',
      (() async {
        final album = Album.fake(id: 'a-2')..name = 'Same Name';
        CapturingClient()
          ..willReturn(json: {'name': 'Same Name', 'year': null})
          ..install();

        final song = Song.fake(album: album);
        final playables = _seedPlayables([song]);

        var notifyCount = 0;
        playables.addListener(() => notifyCount++);

        await AlbumProvider().update(album, name: 'Same Name');
        await _flushMicrotasks();

        expect(song.albumName, 'Same Name');
        expect(notifyCount, 0);
      }),
    );
  });

  group('ArtistProvider rename → PlayableProvider', () {
    test(
      'songs whose artist matches get artistName updated',
      (() async {
        CapturingClient()..willReturn(json: {'name': 'New Artist'})..install();

        final artist = Artist.fake(id: 'ar-1')..name = 'Old';
        final unrelatedArtist = Artist.fake();
        final song = Song.fake(artist: artist);
        final unrelated = Song.fake(artist: unrelatedArtist);
        _seedPlayables([song, unrelated]);

        await ArtistProvider().update(artist, name: 'New Artist');
        await _flushMicrotasks();

        expect(song.artistName, 'New Artist');
        expect(unrelated.artistName, isNot('New Artist'));
        expect(song.albumArtistName, 'New Artist');
      }),
    );

    test(
      'songs where albumArtistId matches but artistId does not get '
      'only albumArtistName updated',
      (() async {
        CapturingClient()..willReturn(json: {'name': 'Renamed AA'})..install();

        final albumArtist = Artist.fake(id: 'aa-1')..name = 'Old AA';
        final featuredArtist = Artist.fake(id: 'ft-1')..name = 'Featured';
        final song = Song.fake(
          artist: featuredArtist,
          albumArtist: albumArtist,
        );
        _seedPlayables([song]);

        await ArtistProvider().update(albumArtist, name: 'Renamed AA');
        await _flushMicrotasks();

        expect(song.albumArtistName, 'Renamed AA');
        expect(song.artistName, 'Featured');
      }),
    );
  });

  group('ArtistProvider rename → AlbumProvider', () {
    test(
      'albums sharing the renamed artist get their artistName updated',
      (() async {
        CapturingClient()
          ..willReturn(json: {'name': 'Rebranded'})
          ..install();

        final artist = Artist.fake(id: 'ar-2')..name = 'Old';
        final unrelatedArtist = Artist.fake();
        final albumProvider = AlbumProvider();
        albumProvider.syncWithVault([
          Album.fake(id: 'al-1', artist: artist),
          Album.fake(id: 'al-2', artist: unrelatedArtist),
        ]);

        var notifyCount = 0;
        albumProvider.addListener(() => notifyCount++);

        await ArtistProvider().update(artist, name: 'Rebranded');
        await _flushMicrotasks();

        expect(albumProvider.byId('al-1')!.artistName, 'Rebranded');
        expect(albumProvider.byId('al-2')!.artistName, isNot('Rebranded'));
        expect(notifyCount, greaterThanOrEqualTo(1));
      }),
    );
  });
}

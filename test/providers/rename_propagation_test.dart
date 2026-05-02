import 'package:app/models/album.dart';
import 'package:app/models/artist.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/album_provider.dart';
import 'package:app/providers/artist_provider.dart';
import 'package:app/providers/playable_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/api_test_setup.dart';

/// Reflective access to PlayableProvider's private vault — providers
/// don't expose a seeding hook, so route through the public
/// `syncWithVault` which writes into the vault for new entries.
PlayableProvider _seedPlayables(List<Song> songs) {
  final provider = PlayableProvider();
  provider.syncWithVault(songs.cast<dynamic>().toList()
      .map((s) => s as dynamic)
      .toList()
      .cast<Song>());
  return provider;
}

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
        // Stream is async — yield once so the subscription fires.
        await Future<void>.delayed(Duration.zero);

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
        await Future<void>.delayed(Duration.zero);

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
        final playables = _seedPlayables([song, unrelated]);

        await ArtistProvider().update(artist, name: 'New Artist');
        await Future<void>.delayed(Duration.zero);

        expect(song.artistName, 'New Artist');
        expect(unrelated.artistName, isNot('New Artist'));
        // The album-artist link is independent (set by Song.fake to the
        // same artist); confirm we updated that field too on the same
        // song.
        expect(song.albumArtistName, 'New Artist');
        // Listener attached after the call so we don't assert count
        // here — the field state is the source of truth.
        expect(playables, isNotNull);
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
        await Future<void>.delayed(Duration.zero);

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
        // Seed via the public sync API.
        albumProvider.syncWithVault([
          Album.fake(id: 'al-1', artist: artist),
          Album.fake(id: 'al-2', artist: unrelatedArtist),
        ]);

        var notifyCount = 0;
        albumProvider.addListener(() => notifyCount++);

        await ArtistProvider().update(artist, name: 'Rebranded');
        await Future<void>.delayed(Duration.zero);

        expect(albumProvider.byId('al-1')!.artistName, 'Rebranded');
        expect(albumProvider.byId('al-2')!.artistName, isNot('Rebranded'));
        expect(notifyCount, greaterThanOrEqualTo(1));
      }),
    );
  });
}

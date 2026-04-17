import 'package:app/models/models.dart';
import 'package:app/ui/screens/screens.dart';
import 'package:app/utils/route_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RouteEntry serialization', () {
    test('round-trips a route with no argument', () {
      final entry = RouteEntry(name: SongsScreen.routeName);
      final json = entry.toJson();
      final restored = RouteEntry.fromJson(json);

      expect(restored.name, SongsScreen.routeName);
      expect(restored.argument, isNull);
    });

    test('round-trips a route with a string ID argument', () {
      final entry = RouteEntry(
        name: AlbumDetailsScreen.routeName,
        argument: 'album-123',
      );
      final json = entry.toJson();
      final restored = RouteEntry.fromJson(json);

      expect(restored.name, AlbumDetailsScreen.routeName);
      expect(restored.argument, 'album-123');
    });

    test('round-trips a route with an int ID argument', () {
      final entry = RouteEntry(
        name: ArtistDetailsScreen.routeName,
        argument: 42,
      );
      final json = entry.toJson();
      final restored = RouteEntry.fromJson(json);

      expect(restored.name, ArtistDetailsScreen.routeName);
      expect(restored.argument, 42);
    });

    test('round-trips a route with a Playlist argument', () {
      final playlist = Playlist.fake(
        id: 'pl-1',
        name: 'My Playlist',
        isSmart: false,
      );
      final entry = RouteEntry(
        name: PlaylistDetailsScreen.routeName,
        argument: playlist,
      );
      final json = entry.toJson();
      final restored = RouteEntry.fromJson(json);

      expect(restored.name, PlaylistDetailsScreen.routeName);
      expect(restored.argument, isA<Playlist>());
      final restoredPlaylist = restored.argument as Playlist;
      expect(restoredPlaylist.id, 'pl-1');
      expect(restoredPlaylist.name, 'My Playlist');
      expect(restoredPlaylist.isSmart, isFalse);
    });

    test('round-trips a route with a Genre argument', () {
      final genre = Genre(
        id: 'g-1',
        name: 'Rock',
        songCount: 42,
        length: 12345,
      );
      final entry = RouteEntry(
        name: GenreDetailsScreen.routeName,
        argument: genre,
      );
      final json = entry.toJson();
      final restored = RouteEntry.fromJson(json);

      expect(restored.name, GenreDetailsScreen.routeName);
      expect(restored.argument, isA<Genre>());
      final restoredGenre = restored.argument as Genre;
      expect(restoredGenre.id, 'g-1');
      expect(restoredGenre.name, 'Rock');
      expect(restoredGenre.songCount, 42);
    });

    test('round-trips a podcast ID argument', () {
      final entry = RouteEntry(
        name: PodcastDetailsScreen.routeName,
        argument: 'podcast-abc',
      );
      final json = entry.toJson();
      final restored = RouteEntry.fromJson(json);

      expect(restored.name, PodcastDetailsScreen.routeName);
      expect(restored.argument, 'podcast-abc');
    });
  });

  group('RouteEntry.buildScreen', () {
    test('returns correct screen for library routes', () {
      expect(
        RouteEntry(name: SongsScreen.routeName).buildScreen(),
        isA<SongsScreen>(),
      );
      expect(
        RouteEntry(name: FavoritesScreen.routeName).buildScreen(),
        isA<FavoritesScreen>(),
      );
      expect(
        RouteEntry(name: PlaylistsScreen.routeName).buildScreen(),
        isA<PlaylistsScreen>(),
      );
      expect(
        RouteEntry(name: ArtistsScreen.routeName).buildScreen(),
        isA<ArtistsScreen>(),
      );
      expect(
        RouteEntry(name: AlbumsScreen.routeName).buildScreen(),
        isA<AlbumsScreen>(),
      );
      expect(
        RouteEntry(name: GenresScreen.routeName).buildScreen(),
        isA<GenresScreen>(),
      );
    });

    test('returns correct screen for detail routes', () {
      expect(
        RouteEntry(name: AlbumDetailsScreen.routeName).buildScreen(),
        isA<AlbumDetailsScreen>(),
      );
      expect(
        RouteEntry(name: ArtistDetailsScreen.routeName).buildScreen(),
        isA<ArtistDetailsScreen>(),
      );
      expect(
        RouteEntry(name: PlaylistDetailsScreen.routeName).buildScreen(),
        isA<PlaylistDetailsScreen>(),
      );
      expect(
        RouteEntry(name: PodcastDetailsScreen.routeName).buildScreen(),
        isA<PodcastDetailsScreen>(),
      );
      expect(
        RouteEntry(name: GenreDetailsScreen.routeName).buildScreen(),
        isA<GenreDetailsScreen>(),
      );
    });

    test('returns null for unknown route', () {
      expect(RouteEntry(name: '/unknown').buildScreen(), isNull);
    });
  });

  group('Playlist.toJson', () {
    test('round-trips through JSON', () {
      final original = Playlist.fake(
        id: 'test-id',
        name: 'Test Playlist',
        isSmart: true,
      );
      final json = original.toJson();
      final restored = Playlist.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.isSmart, original.isSmart);
    });
  });

  group('Genre.toJson', () {
    test('round-trips through JSON', () {
      final original = Genre(
        id: 'rock',
        name: 'Rock',
        songCount: 100,
        length: 36000,
      );
      final json = original.toJson();
      final restored = Genre.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.songCount, original.songCount);
      expect(restored.length, original.length);
    });
  });
}

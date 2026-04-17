import 'package:app/models/models.dart';
import 'package:app/ui/screens/screens.dart';
import 'package:app/utils/route_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A minimal [Route] implementation for testing [RouteStateObserver].
class FakeRoute extends Route {
  FakeRoute({required String name, dynamic arguments})
      : super(settings: RouteSettings(name: name, arguments: arguments));
}

void main() {
  RouteState.persistEnabled = false;

  setUp(() => RouteState.reset());

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

  group('RouteState', () {
    setUp(() => RouteState.reset());

    test('defaults to tab 0 with empty stacks', () {
      expect(RouteState.tabIndex, 0);
      expect(RouteState.stackFor(0), isEmpty);
      expect(RouteState.stackFor(1), isEmpty);
      expect(RouteState.stackFor(2), isEmpty);
    });

    test('setTabIndex updates tab index', () {
      RouteState.setTabIndex(2);
      expect(RouteState.tabIndex, 2);
    });

    test('addEntry appends to the correct tab stack', () {
      RouteState.addEntry(1, RouteEntry(name: '/songs'));
      RouteState.addEntry(1, RouteEntry(name: '/albums'));

      expect(RouteState.stackFor(1).length, 2);
      expect(RouteState.stackFor(1)[0].name, '/songs');
      expect(RouteState.stackFor(1)[1].name, '/albums');
      expect(RouteState.stackFor(0), isEmpty);
    });

    test('removeLastEntry removes the last entry', () {
      RouteState.addEntry(0, RouteEntry(name: '/songs'));
      RouteState.addEntry(0, RouteEntry(name: '/albums'));

      RouteState.removeLastEntry(0);

      expect(RouteState.stackFor(0).length, 1);
      expect(RouteState.stackFor(0).first.name, '/songs');
    });

    test('removeLastEntry does nothing on empty stack', () {
      RouteState.removeLastEntry(0);
      expect(RouteState.stackFor(0), isEmpty);
    });

    test('removeEntryByName removes the matching entry', () {
      RouteState.addEntry(0, RouteEntry(name: '/songs'));
      RouteState.addEntry(0, RouteEntry(name: '/albums'));
      RouteState.addEntry(0, RouteEntry(name: '/album'));

      RouteState.removeEntryByName(0, '/albums');

      expect(RouteState.stackFor(0).length, 2);
      expect(RouteState.stackFor(0)[0].name, '/songs');
      expect(RouteState.stackFor(0)[1].name, '/album');
    });

    test('removeEntryByName removes last occurrence when duplicates exist', () {
      RouteState.addEntry(0, RouteEntry(name: '/songs'));
      RouteState.addEntry(0, RouteEntry(name: '/songs'));

      RouteState.removeEntryByName(0, '/songs');

      expect(RouteState.stackFor(0).length, 1);
      expect(RouteState.stackFor(0).first.name, '/songs');
    });

    test('removeEntryByName does nothing for non-existent name', () {
      RouteState.addEntry(0, RouteEntry(name: '/songs'));
      RouteState.removeEntryByName(0, '/unknown');
      expect(RouteState.stackFor(0).length, 1);
    });

    test('reset clears in-memory state', () {
      RouteState.setTabIndex(1);
      RouteState.addEntry(1, RouteEntry(name: '/songs'));

      RouteState.reset();

      expect(RouteState.tabIndex, 0);
      expect(RouteState.stackFor(0), isEmpty);
      expect(RouteState.stackFor(1), isEmpty);
    });
  });

  group('RouteStateObserver', () {
    late RouteStateObserver observer;

    setUp(() {
      RouteState.reset();
      observer = RouteStateObserver(tabIndex: 0);
    });

    test('didPush adds entry to stack', () {
      observer.didPush(FakeRoute(name: '/songs'), null);

      expect(RouteState.stackFor(0).length, 1);
      expect(RouteState.stackFor(0).first.name, '/songs');
    });

    test('didPush ignores root route', () {
      observer.didPush(FakeRoute(name: '/'), null);
      expect(RouteState.stackFor(0), isEmpty);
    });

    test('didPush preserves arguments', () {
      observer.didPush(
        FakeRoute(name: '/album', arguments: 'album-42'),
        null,
      );

      expect(RouteState.stackFor(0).first.argument, 'album-42');
    });

    test('didPop removes matching top entry', () {
      observer.didPush(FakeRoute(name: '/songs'), null);
      observer.didPush(FakeRoute(name: '/albums'), null);

      observer.didPop(FakeRoute(name: '/albums'), null);

      expect(RouteState.stackFor(0).length, 1);
      expect(RouteState.stackFor(0).first.name, '/songs');
    });

    test('didPop does not remove if name does not match stack top', () {
      observer.didPush(FakeRoute(name: '/songs'), null);
      observer.didPush(FakeRoute(name: '/albums'), null);

      // Pop a route that doesn't match the top (/albums)
      observer.didPop(FakeRoute(name: '/songs'), null);

      // Stack should remain unchanged
      expect(RouteState.stackFor(0).length, 2);
    });

    test('didPop ignores root route', () {
      observer.didPush(FakeRoute(name: '/songs'), null);
      observer.didPop(FakeRoute(name: '/'), null);
      expect(RouteState.stackFor(0).length, 1);
    });

    test('didReplace swaps the top entry', () {
      observer.didPush(FakeRoute(name: '/songs'), null);

      observer.didReplace(
        newRoute: FakeRoute(name: '/albums'),
        oldRoute: FakeRoute(name: '/songs'),
      );

      expect(RouteState.stackFor(0).length, 1);
      expect(RouteState.stackFor(0).first.name, '/albums');
    });

    test('didReplace handles null oldRoute (add only)', () {
      observer.didReplace(
        newRoute: FakeRoute(name: '/songs'),
        oldRoute: null,
      );

      expect(RouteState.stackFor(0).length, 1);
      expect(RouteState.stackFor(0).first.name, '/songs');
    });

    test('didRemove removes matching entry from middle of stack', () {
      observer.didPush(FakeRoute(name: '/songs'), null);
      observer.didPush(FakeRoute(name: '/albums'), null);
      observer.didPush(FakeRoute(name: '/album'), null);

      observer.didRemove(FakeRoute(name: '/albums'), null);

      expect(RouteState.stackFor(0).length, 2);
      expect(RouteState.stackFor(0)[0].name, '/songs');
      expect(RouteState.stackFor(0)[1].name, '/album');
    });

    test('didRemove ignores root route', () {
      observer.didPush(FakeRoute(name: '/songs'), null);
      observer.didRemove(FakeRoute(name: '/'), null);
      expect(RouteState.stackFor(0).length, 1);
    });

    test('tracks correct tab index', () {
      final observer1 = RouteStateObserver(tabIndex: 1);
      final observer2 = RouteStateObserver(tabIndex: 2);

      observer.didPush(FakeRoute(name: '/songs'), null);
      observer1.didPush(FakeRoute(name: '/albums'), null);
      observer2.didPush(FakeRoute(name: '/album'), null);

      expect(RouteState.stackFor(0).first.name, '/songs');
      expect(RouteState.stackFor(1).first.name, '/albums');
      expect(RouteState.stackFor(2).first.name, '/album');
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

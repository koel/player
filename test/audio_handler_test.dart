import 'dart:async';
import 'dart:math';

import 'package:app/app_state.dart';
import 'package:app/audio_handler.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/download_provider.dart';
import 'package:app/providers/playable_provider.dart';
import 'package:app/values/queue_state.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:version/version.dart';

import 'helpers/api_test_setup.dart';
import 'audio_handler_test.mocks.dart';

class FirstIndexRandom implements Random {
  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) => 0;
}

@GenerateMocks([AudioPlayer, PlayableProvider, DownloadProvider])
void main() {
  late MockAudioPlayer player;
  late MockPlayableProvider playableProvider;
  late MockDownloadProvider downloadProvider;
  late StreamController<PlaybackEvent> playbackEvents;
  late StreamController<ProcessingState> processingStates;
  late KoelAudioHandler handler;
  late CapturingClient client;

  setUpAll(() async => await initApiTestEnvironment());

  setUp(() async {
    AppState.clear();
    playbackEvents = StreamController<PlaybackEvent>.broadcast();
    processingStates = StreamController<ProcessingState>.broadcast();

    player = MockAudioPlayer();
    when(player.playbackEventStream).thenAnswer((_) => playbackEvents.stream);
    when(player.processingStateStream)
        .thenAnswer((_) => processingStates.stream);
    when(player.processingState).thenReturn(ProcessingState.ready);
    when(player.playing).thenReturn(false);
    when(player.shuffleModeEnabled).thenReturn(false);
    when(player.position).thenReturn(Duration.zero);
    when(player.bufferedPosition).thenReturn(Duration.zero);
    when(player.speed).thenReturn(1.0);
    when(player.setVolume(any)).thenAnswer((_) async {});
    when(player.setFilePath(any)).thenAnswer((_) async => Duration.zero);
    when(player.setUrl(any)).thenAnswer((_) async => Duration.zero);
    when(player.seek(any)).thenAnswer((_) async {});
    when(player.play()).thenAnswer((_) async {});
    when(player.stop()).thenAnswer((_) async {});

    playableProvider = MockPlayableProvider();
    downloadProvider = MockDownloadProvider();
    when(downloadProvider.getForPlayable(any)).thenReturn(null);

    handler = KoelAudioHandler(
      player: player,
      random: FirstIndexRandom(),
      sourceLoadTimeout: const Duration(milliseconds: 50),
      browseLoadTimeout: const Duration(milliseconds: 50),
      applicationId: 'test.koel.sentinel',
    );

    client = CapturingClient();
    client.install();
    setUpApiTest();

    await handler.init(
      playableProvider: playableProvider,
      downloadProvider: downloadProvider,
    );
  });

  tearDown(() async {
    await playbackEvents.close();
    await processingStates.close();
    tearDownApiTest();
  });

  Song registerSong() {
    final song = Song.fake();
    when(playableProvider.byId(song.id)).thenReturn(song);
    return song;
  }

  AudioProcessingState currentProcessingState() =>
      handler.playbackState.value.processingState;

  test('advertises Android Auto playback actions before loading a queue', () {
    final state = handler.playbackState.value;

    expect(
      state.controls.map((control) => control.action),
      isNot(contains(MediaAction.stop)),
    );
    expect(state.systemActions, contains(MediaAction.playFromMediaId));
    expect(state.systemActions, contains(MediaAction.skipToQueueItem));
    expect(state.systemActions, contains(MediaAction.setShuffleMode));
    expect(state.androidCompactActionIndices, [0, 1, 2]);
  });

  test('restores the queue after app data becomes available', () async {
    final song = registerSong();
    AppState.set(
      ['app', 'apiVersion'],
      Version.parse('6.11.6'),
    );
    AppState.set(
      ['app', 'queueState'],
      QueueState(playables: [song]),
    );
    when(playableProvider.syncWithVault(any)).thenReturn([song]);
    when(player.positionStream).thenAnswer((_) => const Stream.empty());

    await handler.restoreQueue();
    await pumpEventQueue();

    expect(handler.queue.value.map((item) => item.id), [song.id]);

    await handler.cleanUpUponLogout();
    final nextSong = registerSong();
    AppState.set(
      ['app', 'queueState'],
      QueueState(playables: [nextSong]),
    );
    when(playableProvider.syncWithVault(any)).thenReturn([nextSong]);

    await handler.restoreQueue();
    await pumpEventQueue();

    expect(handler.queue.value.map((item) => item.id), [nextSong.id]);
    expect(
      client.requests.where((request) => request.url.contains('/queue/state')),
      hasLength(2),
    );
    verify(playableProvider.syncWithVault(any)).called(2);
  });

  test('browses navigation cards before recent songs and caches the Home',
      () async {
    final recent = registerSong();
    when(playableProvider.parseFromJson(any)).thenReturn([recent]);
    client.willReturn(json: {
      'recently_played_songs': [<String, dynamic>{}],
    });

    expect(
      KoelAudioHandler
          .androidBrowsableRootExtras[AndroidContentStyle.supportedKey],
      isTrue,
    );

    final root = await handler.getChildren(AudioService.browsableRootId);
    expect(root, hasLength(1));
    expect(root.single.title, 'Home');
    expect(root.single.playable, isFalse);
    expect(
      root.single.extras?[AndroidContentStyle.browsableHintKey],
      AndroidContentStyle.gridItemHintValue,
    );
    expect(
      root.single.extras?[AndroidContentStyle.playableHintKey],
      AndroidContentStyle.listItemHintValue,
    );
    expect(await handler.getMediaItem(root.single.id), root.single);

    final children = await handler.getChildren(root.single.id);
    expect(client.requests.single.url, contains('/overview'));
    expect(children.map((item) => item.id), [
      'playlists',
      'albums',
      'artists',
      'recently-played/playable/${recent.id}',
    ]);
    expect(children.take(3).map((item) => item.title),
        ['Playlists', 'Albums', 'Artists']);
    expect(children.take(3).every((item) => item.playable == false), isTrue);
    expect(
      children.take(3).every((item) =>
          item.extras?[AndroidContentStyle.browsableHintKey] ==
          AndroidContentStyle.gridItemHintValue),
      isTrue,
    );
    expect(
      children.take(3).every((item) =>
          item.extras?['android.media.browse.CONTENT_STYLE_GROUP_TITLE_HINT'] ==
          'Browse'),
      isTrue,
    );
    expect(
      children
          .skip(3)
          .single
          .extras?['android.media.browse.CONTENT_STYLE_GROUP_TITLE_HINT'],
      'Recently played',
    );
    expect(
      children.take(3).map((item) => item.artUri.toString()),
      [
        'android.resource://test.koel.sentinel/drawable/android_auto_playlists',
        'android.resource://test.koel.sentinel/drawable/android_auto_albums',
        'android.resource://test.koel.sentinel/drawable/android_auto_artists',
      ],
    );
    for (final item in children) {
      expect(await handler.getMediaItem(item.id), item);
    }
    expect(await handler.getChildren('unknown'), isEmpty);

    client.willReturn(status: 500, json: {});
    expect(await handler.getChildren(root.single.id), children);
  });

  test('shares an overlapping Home load across browse subscriptions', () async {
    final recentSong = registerSong();
    when(playableProvider.parseFromJson(any)).thenReturn([recentSong]);
    final responseGate = Completer<void>();
    client.willReturn(
      waitFor: responseGate.future,
      json: {
        'recently_played_songs': [
          {'id': recentSong.id}
        ],
      },
    );

    final firstRequest = handler.getChildren('home');
    await Future<void>.delayed(Duration.zero);
    final secondRequest = handler.getChildren('home');
    await Future<void>.delayed(Duration.zero);
    responseGate.complete();

    final results = await Future.wait([firstRequest, secondRequest]);
    expect(client.requests, hasLength(1));
    expect(results[0], results[1]);
    expect(results[0].last.id, 'recently-played/playable/${recentSong.id}');
    expect(await handler.getMediaItem(results[0].last.id), results[0].last);
  });

  test('browses and caches album and artist catalogs', () async {
    client.willReturn(json: {
      'data': [
        {
          'id': 'album-1',
          'name': 'Album One',
          'artist_id': 'artist-1',
          'artist_name': 'Artist One',
          'cover': 'https://example.com/album.jpg',
        },
        {
          'id': 'album-2',
          'name': 'Album Two',
          'artist_id': 'artist-2',
          'artist_name': 'Artist Two',
          'cover': 'file:///private/cover.jpg',
        },
      ],
    });
    final albums = await handler.getChildren('albums');
    expect(client.requests.last.url,
        contains('/albums?page=1&sort=name&order=asc'));
    expect(albums.map((item) => item.id), ['album:album-1', 'album:album-2']);
    expect(albums.map((item) => item.title), ['Album One', 'Album Two']);
    expect(albums.map((item) => item.artist), ['Artist One', 'Artist Two']);
    expect(albums.first.artUri.toString(), 'https://example.com/album.jpg');
    expect(albums.last.artUri, isNull);
    expect(
        albums.every((item) =>
            item.extras?[AndroidContentStyle.playableHintKey] ==
            AndroidContentStyle.listItemHintValue),
        isTrue);
    expect(await handler.getMediaItem(albums.first.id), albums.first);
    final stalledCatalog = Completer<void>();
    client.willReturn(waitFor: stalledCatalog.future, json: {'data': []});
    expect(await handler.getChildren('albums'), albums);

    client.willReturn(json: {
      'data': [
        {
          'id': 'artist-1',
          'name': 'Artist One',
          'image': 'https://example.com/artist.jpg',
        },
        {
          'id': 'artist-2',
          'name': 'Artist Two',
          'image': 'content://private/artist.jpg',
        },
      ],
    });
    final artists = await handler.getChildren('artists');
    expect(client.requests.last.url,
        contains('/artists?page=1&sort=name&order=asc'));
    expect(
        artists.map((item) => item.id), ['artist:artist-1', 'artist:artist-2']);
    expect(artists.map((item) => item.title), ['Artist One', 'Artist Two']);
    expect(artists.first.artUri.toString(), 'https://example.com/artist.jpg');
    expect(artists.last.artUri, isNull);
    expect(
        artists.every((item) =>
            item.extras?[AndroidContentStyle.playableHintKey] ==
            AndroidContentStyle.listItemHintValue),
        isTrue);
    expect(await handler.getMediaItem(artists.first.id), artists.first);
    final stalledArtists = Completer<void>();
    client.willReturn(waitFor: stalledArtists.future, json: {'data': []});
    expect(await handler.getChildren('artists'), artists);
  });

  test('shares initial collection loads across browse subscriptions', () async {
    final songs = List.generate(2, (_) => registerSong());
    final albumGate = Completer<List<Playable>>();
    when(playableProvider.fetchForAlbum('album-1'))
        .thenAnswer((_) => albumGate.future);

    final firstAlbumRequest = handler.getChildren('album:album-1');
    await Future<void>.delayed(Duration.zero);
    final secondAlbumRequest = handler.getChildren('album:album-1');
    albumGate.complete(songs);

    final albumResults =
        await Future.wait([firstAlbumRequest, secondAlbumRequest]);
    expect(albumResults[0], albumResults[1]);
    expect(albumResults[0], hasLength(3));
    verify(playableProvider.fetchForAlbum('album-1')).called(1);

    final artistGate = Completer<List<Playable>>();
    when(playableProvider.fetchForArtist('artist-1'))
        .thenAnswer((_) => artistGate.future);
    final firstArtistRequest = handler.getChildren('artist:artist-1');
    await Future<void>.delayed(Duration.zero);
    final secondArtistRequest = handler.getChildren('artist:artist-1');
    artistGate.complete(songs);

    final artistResults =
        await Future.wait([firstArtistRequest, secondArtistRequest]);
    expect(artistResults[0], artistResults[1]);
    expect(artistResults[0], hasLength(3));
    verify(playableProvider.fetchForArtist('artist-1')).called(1);
  });

  List<String> queueIds(Iterable<MediaItem> items) =>
      items.map((item) => item.id).toList();

  test('plays an album selection in context when its song is already queued',
      () async {
    final songs = List.generate(3, (_) => registerSong());
    final unrelatedSong = registerSong();
    when(playableProvider.fetchForAlbum('album-1'))
        .thenAnswer((_) async => songs);
    await handler.replaceQueue(
      [songs[1], unrelatedSong],
      autoPlay: false,
    );

    final children = await handler.getChildren('album:album-1');

    expect(children.first.title, 'Shuffle Play');
    expect(
      children.skip(1).map((item) => item.title),
      songs.map((song) => song.title),
    );
    expect(await handler.getMediaItem(children[1].id), children[1]);

    when(playableProvider.fetchForAlbum('album-1'))
        .thenThrow(Exception('offline'));
    expect(await handler.getChildren('album:album-1'), children);

    await handler.playFromMediaId(children[2].id);
    expect(
      queueIds(handler.queue.value),
      songs.map((song) => song.id).toList(),
    );
    expect(handler.mediaItem.value?.id, songs[1].id);
    verify(player.setUrl(songs[1].sourceUrl)).called(1);
  });

  test('plays an artist selection in its song context', () async {
    final songs = List.generate(3, (_) => registerSong());
    final unrelatedSong = registerSong();
    when(playableProvider.fetchForArtist('artist-1'))
        .thenAnswer((_) async => songs);
    await handler.replaceQueue(
      [songs[1], unrelatedSong],
      autoPlay: false,
    );

    final children = await handler.getChildren('artist:artist-1');

    expect(children.first.id, 'shuffle/artist/artist-1');
    expect(children.first.title, 'Shuffle Play');
    expect(
      children.skip(1).map((item) => item.id),
      songs.map((song) => 'artist/artist-1/playable/${song.id}'),
    );
    expect(await handler.getMediaItem(children.first.id), children.first);
    expect(await handler.getMediaItem(children[2].id), children[2]);
    final stalledDetails = Completer<List<Playable>>();
    when(playableProvider.fetchForArtist('artist-1'))
        .thenAnswer((_) => stalledDetails.future);
    expect(await handler.getChildren('artist:artist-1'), children);

    await handler.playFromMediaId(children[2].id);
    expect(handler.queue.value.map((item) => item.id),
        songs.map((song) => song.id));
    expect(handler.mediaItem.value?.id, songs[1].id);
    verify(player.setUrl(songs[1].sourceUrl)).called(1);
    verify(player.play()).called(1);
  });

  test('bounds slow Android Auto browse requests', () async {
    final root = await handler.getChildren(AudioService.browsableRootId);
    final pendingOverview = Completer<void>();
    client.willReturn(
      waitFor: pendingOverview.future,
      json: {'recently_played_songs': []},
    );

    expect(
      (await handler.getChildren(root.single.id)).map((item) => item.id),
      ['playlists', 'albums', 'artists'],
    );

    final pendingAlbum = Completer<List<Playable>>();
    when(playableProvider.fetchForAlbum('slow'))
        .thenAnswer((_) => pendingAlbum.future);
    expect(await handler.getChildren('album:slow'), isEmpty);
  });

  test('clears account-specific browser and playback state on logout',
      () async {
    final root = await handler.getChildren(AudioService.browsableRootId);
    client.willReturn(json: {});
    await handler.getChildren(root.single.id);
    client.willReturn(json: {
      'data': [
        {
          'id': 'album-1',
          'name': 'Private album',
          'artist_id': 'artist-1',
          'artist_name': 'Artist',
          'cover': null,
        },
      ],
    });
    final albums = await handler.getChildren('albums');
    final song = registerSong();
    when(playableProvider.fetchForAlbum('album-1'))
        .thenAnswer((_) async => [song]);
    final songs = await handler.getChildren(albums.first.id);
    await handler.playFromMediaId(songs.last.id);
    await pumpEventQueue();

    client.willReturn(json: {
      'data': [
        {
          'id': 'artist-1',
          'name': 'Private artist',
          'image': null,
        },
      ],
    });
    final artists = await handler.getChildren('artists');
    final artistSong = registerSong();
    when(playableProvider.fetchForArtist('artist-1'))
        .thenAnswer((_) async => [artistSong]);
    final artistSongs = await handler.getChildren(artists.first.id);

    await handler.cleanUpUponLogout();

    expect(await handler.getChildren(root.single.id), isEmpty);
    expect(await handler.getChildren('albums'), isEmpty);
    expect(await handler.getChildren('artists'), isEmpty);
    expect(await handler.getChildren(albums.first.id), isEmpty);
    expect(await handler.getChildren(artists.first.id), isEmpty);
    expect(await handler.getMediaItem(albums.first.id), isNull);
    expect(await handler.getMediaItem(artists.first.id), isNull);
    expect(await handler.getMediaItem(songs.last.id), isNull);
    expect(await handler.getMediaItem(artistSongs.last.id), isNull);
    expect(handler.queue.value, isEmpty);
    expect(handler.mediaItem.value, isNull);
  });

  test('does not repopulate browser caches after logout', () async {
    final overviewGate = Completer<void>();
    client.willReturn(
      status: 500,
      waitFor: overviewGate.future,
      json: {},
    );
    final overviewRequest = handler.getChildren('home');
    await Future<void>.delayed(Duration.zero);

    final albumCatalogGate = Completer<void>();
    client.willReturn(
      waitFor: albumCatalogGate.future,
      json: {
        'data': [
          {
            'id': 'album-1',
            'name': 'Previous account album',
            'artist_id': 'artist-1',
            'artist_name': 'Artist',
            'cover': null,
          },
        ],
      },
    );
    final albumCatalogRequest = handler.getChildren('albums');
    await Future<void>.delayed(Duration.zero);

    final artistCatalogGate = Completer<void>();
    client.willReturn(
      waitFor: artistCatalogGate.future,
      json: {
        'data': [
          {
            'id': 'artist-1',
            'name': 'Previous account artist',
            'image': null,
          },
        ],
      },
    );
    final artistCatalogRequest = handler.getChildren('artists');
    await Future<void>.delayed(Duration.zero);

    final albumSong = registerSong();
    final pendingAlbum = Completer<List<Playable>>();
    when(playableProvider.fetchForAlbum('album-1'))
        .thenAnswer((_) => pendingAlbum.future);
    final albumRequest = handler.getChildren('album:album-1');
    final artistSong = registerSong();
    final pendingArtist = Completer<List<Playable>>();
    when(playableProvider.fetchForArtist('artist-1'))
        .thenAnswer((_) => pendingArtist.future);
    final artistRequest = handler.getChildren('artist:artist-1');
    await Future<void>.delayed(Duration.zero);

    await handler.cleanUpUponLogout();
    overviewGate.complete();
    albumCatalogGate.complete();
    artistCatalogGate.complete();
    pendingAlbum.complete([albumSong]);
    pendingArtist.complete([artistSong]);

    expect(await overviewRequest, isEmpty);
    expect(await albumCatalogRequest, isEmpty);
    expect(await artistCatalogRequest, isEmpty);
    expect(await albumRequest, isEmpty);
    expect(await artistRequest, isEmpty);
    expect(await handler.getMediaItem('album:album-1'), isNull);
    expect(await handler.getMediaItem('artist:artist-1'), isNull);
    expect(await handler.getChildren('home'), isEmpty);
    expect(await handler.getChildren('albums'), isEmpty);
    expect(await handler.getChildren('artists'), isEmpty);
  });

  test('blocks browsing while logout cleanup is in progress', () async {
    client.willReturn(json: {});
    final home = await handler.getChildren('home');
    expect(home, isNotEmpty);
    final stopGate = Completer<void>();
    when(player.stop()).thenAnswer((_) => stopGate.future);

    final cleanup = handler.cleanUpUponLogout();
    await Future<void>.delayed(Duration.zero);

    expect(await handler.getChildren(AudioService.browsableRootId), isEmpty);
    expect(await handler.getMediaItem('home'), isNull);
    stopGate.complete();
    await cleanup;

    await handler.restoreQueue();
    expect(await handler.getChildren(AudioService.browsableRootId),
        [isA<MediaItem>().having((item) => item.id, 'id', 'home')]);
  });

  test('does not resume an Android Auto selection after logout', () async {
    final songs = List.generate(2, (_) => registerSong());
    when(playableProvider.fetchForArtist('artist-1'))
        .thenAnswer((_) async => songs);
    final children = await handler.getChildren('artist:artist-1');
    final sourceGate = Completer<Duration?>();
    when(player.setUrl(songs.first.sourceUrl))
        .thenAnswer((_) => sourceGate.future);

    final playback = handler.playFromMediaId(children[1].id);
    await untilCalled(player.setUrl(songs.first.sourceUrl));
    await handler.cleanUpUponLogout();
    sourceGate.complete(Duration.zero);
    await playback;

    expect(handler.queue.value, isEmpty);
    expect(handler.mediaItem.value, isNull);
    verifyNever(player.play());
  });

  test('supports native queue selection and reversible shuffle', () async {
    final songs = List.generate(4, (_) => registerSong());

    await handler.replaceQueue(songs, autoPlay: false);
    final originalIds = queueIds(handler.queue.value);
    await handler.skipToQueueItem(1);
    expect(handler.mediaItem.value?.id, songs[1].id);

    final shuffleControl = handler.playbackState.value.controls.singleWhere(
      (control) => control.label == 'Turn shuffle on',
    );
    expect(shuffleControl.customAction?.name, 'enableShuffle');
    expect(shuffleControl.androidIcon, 'drawable/audio_service_shuffle');

    await handler.customAction(shuffleControl.customAction!.name);
    final shuffledIds = queueIds(handler.queue.value);
    expect(
        handler.playbackState.value.shuffleMode, AudioServiceShuffleMode.all);
    expect(shuffledIds.first, songs[1].id);
    expect(shuffledIds, unorderedEquals(originalIds));
    final activeShuffleControl = handler.playbackState.value.controls
        .singleWhere((control) => control.label == 'Turn shuffle off');
    expect(activeShuffleControl.customAction?.name, 'disableShuffle');
    expect(
        activeShuffleControl.androidIcon, 'drawable/audio_service_shuffle_on');

    await handler.customAction(activeShuffleControl.customAction!.name);
    expect(
        handler.playbackState.value.shuffleMode, AudioServiceShuffleMode.none);
    expect(queueIds(handler.queue.value), originalIds);
    expect(handler.mediaItem.value?.id, songs[1].id);
    expect(handler.playbackState.value.queueIndex, 1);
  });

  test('does not pin the previous item when shuffling a replacement queue',
      () async {
    final songs = List.generate(4, (_) => registerSong());

    await handler.replaceQueue(songs);
    await handler.skipToQueueItem(2);
    await handler.replaceQueue(songs, shuffle: true, autoPlay: false);

    expect(handler.queue.value.first.id, isNot(songs[2].id));
  });

  test('queue mutations invalidate an active shuffle snapshot', () async {
    final songs = List.generate(4, (_) => registerSong());
    final originalIds = songs.map((song) => song.id).toList();

    await handler.replaceQueue(songs, shuffle: true, autoPlay: false);
    expect(
        handler.playbackState.value.shuffleMode, AudioServiceShuffleMode.all);
    expect(queueIds(handler.queue.value), unorderedEquals(originalIds));

    final removedId = handler.queue.value[1].id;
    await handler.removeQueueItemAt(1);
    expect(
        handler.playbackState.value.shuffleMode, AudioServiceShuffleMode.none);

    await handler.setShuffleMode(AudioServiceShuffleMode.none);
    expect(queueIds(handler.queue.value), isNot(contains(removedId)));

    await handler.replaceQueue(songs, shuffle: true, autoPlay: false);
    await handler.clearQueue();
    await handler.setShuffleMode(AudioServiceShuffleMode.none);
    expect(handler.queue.value, isEmpty);
  });

  test('keeps the active queue index correct after queue mutations', () async {
    final songs = List.generate(4, (_) => registerSong());
    await handler.replaceQueue(songs, autoPlay: false);
    await handler.skipToQueueItem(2);

    await handler.removeQueueItemAt(0);
    expect(handler.mediaItem.value?.id, songs[2].id);
    expect(handler.playbackState.value.queueIndex, 1);

    handler.moveQueueItem(0, 3);
    expect(handler.mediaItem.value?.id, songs[2].id);
    expect(handler.playbackState.value.queueIndex, 0);
  });

  test('updates the active index when reordering through queue helpers',
      () async {
    final songs = List.generate(3, (_) => registerSong());
    await handler.replaceQueue(songs, autoPlay: false);
    await handler.skipToQueueItem(2);

    await handler.queueAfterCurrent(songs[0]);
    expect(handler.playbackState.value.queueIndex, 1);

    await handler.replaceQueue(songs, autoPlay: false);
    await handler.skipToQueueItem(2);
    await handler.queueToBottom(songs[0]);
    expect(handler.playbackState.value.queueIndex, 1);
  });

  test('stops playback when removing the only active queue item', () async {
    final song = registerSong();
    await handler.replaceQueue([song]);

    await handler.removeQueueItemAt(0);

    verify(player.stop()).called(1);
    expect(handler.queue.value, isEmpty);
    expect(handler.mediaItem.value, isNull);
    expect(handler.playbackState.value.queueIndex, -1);
  });

  test('ignores queue selections outside the queue', () async {
    final songs = List.generate(2, (_) => registerSong());
    await handler.replaceQueue(songs, autoPlay: false);

    await handler.skipToQueueItem(-1);
    await handler.skipToQueueItem(songs.length);

    verifyNever(player.setUrl(any));
    expect(handler.mediaItem.value, isNull);
  });

  test('plays a queue item selected by media id', () async {
    final first = registerSong();
    final second = registerSong();

    await handler.replaceQueue([first, second], autoPlay: false);
    await handler.playFromMediaId(second.id);

    verify(player.setUrl(second.sourceUrl)).called(1);
    expect(handler.mediaItem.value?.id, second.id);
  });

  test('keeps Now Playing state while manually switching tracks', () async {
    final first = registerSong();
    final second = registerSong();
    final sourceReady = Completer<Duration?>();

    when(player.playing).thenReturn(true);
    when(player.setUrl(second.sourceUrl)).thenAnswer((_) => sourceReady.future);
    await handler.replaceQueue([first, second]);

    final switchFuture = handler.skipToNext();
    await Future<void>.delayed(Duration.zero);
    when(player.processingState).thenReturn(ProcessingState.idle);
    playbackEvents.add(PlaybackEvent());
    await Future<void>.delayed(Duration.zero);

    expect(handler.mediaItem.value?.id, second.id);
    expect(handler.playbackState.value.queueIndex, 1);
    expect(handler.playbackState.value.processingState,
        AudioProcessingState.loading);
    expect(handler.playbackState.value.playing, isTrue);

    when(player.processingState).thenReturn(ProcessingState.ready);
    sourceReady.complete(Duration.zero);
    await switchFuture;
    expect(handler.playbackState.value.processingState,
        AudioProcessingState.ready);
    expect(handler.playbackState.value.playing, isTrue);
  });

  test('does not expose completed during automatic advance', () async {
    final first = registerSong();
    final second = registerSong();

    when(player.playing).thenReturn(true);
    await handler.replaceQueue([first, second]);
    when(player.processingState).thenReturn(ProcessingState.completed);
    when(player.playing).thenReturn(false);
    playbackEvents.add(PlaybackEvent());
    await Future<void>.delayed(Duration.zero);

    expect(handler.playbackState.value.processingState,
        AudioProcessingState.loading);
    expect(handler.playbackState.value.playing, isTrue);
    when(player.processingState).thenReturn(ProcessingState.ready);
    when(player.playing).thenReturn(true);
    processingStates.add(ProcessingState.completed);
    await Future<void>.delayed(Duration.zero);

    expect(handler.mediaItem.value?.id, second.id);
    expect(handler.playbackState.value.queueIndex, 1);
    expect(handler.playbackState.value.processingState,
        AudioProcessingState.ready);
    expect(handler.playbackState.value.playing, isTrue);
  });

  test('exposes completed at the end of the queue', () async {
    final song = registerSong();

    when(player.playing).thenReturn(true);
    await handler.replaceQueue([song]);
    when(player.processingState).thenReturn(ProcessingState.completed);
    playbackEvents.add(PlaybackEvent());
    await Future<void>.delayed(Duration.zero);

    expect(handler.playbackState.value.processingState,
        AudioProcessingState.completed);
  });

  test('streams a song that has not been downloaded', () async {
    final song = registerSong();

    await handler.replaceQueue([song]);

    verify(player.setUrl(song.sourceUrl)).called(1);
    verifyNever(player.setFilePath(any));
  });

  test('plays a downloaded song from its local file', () async {
    final song = registerSong();
    when(downloadProvider.getForPlayable(song))
        .thenReturn(Download(playable: song, path: '/downloads/song.mp3'));

    await handler.replaceQueue([song]);

    verify(player.setFilePath('/downloads/song.mp3')).called(1);
    verifyNever(player.setUrl(any));
  });

  test('gives up on a source that never becomes playable', () async {
    final song = registerSong();
    when(player.setUrl(any)).thenAnswer((_) => Completer<Duration?>().future);

    await handler.replaceQueue([song]);

    verify(player.stop()).called(1);
    expect(currentProcessingState(), AudioProcessingState.error);
  });

  test('reports a source that fails outright', () async {
    final song = registerSong();
    when(player.setUrl(any)).thenThrow(Exception('no route to host'));

    await handler.replaceQueue([song]);

    verify(player.stop()).called(1);
    expect(currentProcessingState(), AudioProcessingState.error);
  });

  test('skips past a song the server refuses to serve', () async {
    final broken = registerSong();
    final next = registerSong();
    when(player.setUrl(broken.sourceUrl)).thenThrow(Exception('404'));

    await handler.replaceQueue([broken, next]);

    verify(player.setUrl(next.sourceUrl)).called(1);
    expect(handler.mediaItem.value?.id, next.id);
    expect(currentProcessingState(), isNot(AudioProcessingState.error));
  });

  test('stays put when the load stalls instead of skipping', () async {
    final stalled = registerSong();
    final next = registerSong();
    when(player.setUrl(stalled.sourceUrl))
        .thenAnswer((_) => Completer<Duration?>().future);

    await handler.replaceQueue([stalled, next]);

    verifyNever(player.setUrl(next.sourceUrl));
    expect(handler.mediaItem.value?.id, stalled.id);
    expect(currentProcessingState(), AudioProcessingState.error);
  });

  test('gives up once too many songs fail in a row', () async {
    final songs = List.generate(
      KoelAudioHandler.MAX_ERROR_COUNT + 3,
      (_) => registerSong(),
    );
    when(player.setUrl(any)).thenThrow(Exception('404'));

    await handler.replaceQueue(songs);

    verify(player.setUrl(any)).called(KoelAudioHandler.MAX_ERROR_COUNT);
    expect(currentProcessingState(), AudioProcessingState.error);
  });

  test('stops skipping at the end of the queue', () async {
    final broken = registerSong();
    when(player.setUrl(any)).thenThrow(Exception('404'));

    await handler.replaceQueue([broken]);

    expect(currentProcessingState(), AudioProcessingState.error);
  });

  test('a song that plays clears the run of failures', () async {
    final songs = List.generate(6, (_) => registerSong());
    when(player.setUrl(any)).thenThrow(Exception('404'));
    when(player.setUrl(songs[1].sourceUrl))
        .thenAnswer((_) async => Duration.zero);

    // Fails on the first song, skips onto the second, which plays.
    await handler.replaceQueue(songs);
    expect(handler.mediaItem.value?.id, songs[1].id);

    // The three that follow get a full budget of their own, rather than
    // inheriting the failure that came before the song that played.
    await handler.skipToNext();

    verify(player.setUrl(songs[4].sourceUrl)).called(1);
    verifyNever(player.setUrl(songs[5].sourceUrl));
  });

  test('can still skip to the next song after a stalled load', () async {
    final stalled = registerSong();
    final next = registerSong();
    when(player.setUrl(stalled.sourceUrl))
        .thenAnswer((_) => Completer<Duration?>().future);

    await handler.replaceQueue([stalled, next]);
    expect(currentProcessingState(), AudioProcessingState.error);

    await handler.skipToNext();

    verify(player.setUrl(next.sourceUrl)).called(1);
    expect(currentProcessingState(), isNot(AudioProcessingState.error));
  });

  test('play retries the current song after a failed load', () async {
    final song = registerSong();
    final firstAttempt = Completer<Duration?>();
    when(player.setUrl(song.sourceUrl)).thenAnswer((_) => firstAttempt.future);

    await handler.replaceQueue([song]);
    expect(currentProcessingState(), AudioProcessingState.error);

    when(player.setUrl(song.sourceUrl)).thenAnswer((_) async => Duration.zero);
    await handler.play();

    verify(player.setUrl(song.sourceUrl)).called(2);
    expect(currentProcessingState(), isNot(AudioProcessingState.error));
  });

  test('surfaces an error emitted by the player itself', () async {
    final song = registerSong();
    await handler.replaceQueue([song]);
    expect(currentProcessingState(), isNot(AudioProcessingState.error));

    playbackEvents.addError(Exception('platform decoding failure'));
    await pumpEventQueue();

    expect(currentProcessingState(), AudioProcessingState.error);
    verify(player.stop()).called(1);
  });

  test('regression Home caps recent songs below grouped navigation', () async {
    final recent = List.generate(13, (_) => registerSong());
    when(playableProvider.parseFromJson(any)).thenReturn(recent);
    client.willReturn(
        json: {'recently_played_songs': List.filled(13, <String, dynamic>{})});
    final children = await handler.getChildren('home');
    final navigation = children.take(3);
    final recentItems = children.skip(3);
    expect(children, hasLength(15));
    expect(
        navigation.map((item) => item.id), ['playlists', 'albums', 'artists']);
    expect(recentItems.map((item) => item.id),
        recent.take(12).map((song) => 'recently-played/playable/${song.id}'));
    expect(
        navigation.every((item) =>
            item.extras?[
                'android.media.browse.CONTENT_STYLE_GROUP_TITLE_HINT'] ==
            'Browse'),
        isTrue);
    expect(
        recentItems.every((item) =>
            item.extras?[
                'android.media.browse.CONTENT_STYLE_GROUP_TITLE_HINT'] ==
            'Recently played'),
        isTrue);
    expect(await handler.getMediaItem('playlists'), children.first);
    final selected = children[8];
    expect(await handler.getMediaItem(selected.id), selected);
    await handler.replaceQueue([registerSong()], autoPlay: false);
    await handler.playFromMediaId(selected.id);
    expect(handler.queue.value.map((item) => item.id),
        recent.take(12).map((song) => song.id));
    expect(handler.mediaItem.value?.id, recent[5].id);
    verify(player.setUrl(recent[5].sourceUrl)).called(1);
  });

  test('regression playlist catalog flattens folders and contextual list songs',
      () async {
    client.willReturn(json: {
      'data': [
        {
          'id': 'p1',
          'name': 'One',
          'is_smart': false,
          'folder_id': 'folder',
          'cover': 'https://example.com/p.jpg'
        },
        {
          'id': 'p2',
          'name': 'Two',
          'is_smart': false,
          'folder_id': null,
          'cover': null
        },
      ]
    });
    final catalog = await handler.getChildren('playlists');
    expect(catalog.map((item) => item.id), ['playlist:p1', 'playlist:p2']);
    expect(catalog[0].artUri.toString(), 'https://example.com/p.jpg');
    expect(catalog[1].artUri, isNull);
    expect(await handler.getMediaItem(catalog[0].id), catalog[0]);
    final songs = [registerSong(), registerSong()];
    when(playableProvider.fetchForPlaylist('p1'))
        .thenAnswer((_) async => songs);
    final details = await handler.getChildren('playlist:p1');
    expect(details.first.title, 'Shuffle Play');
    expect(catalog.first.extras?[AndroidContentStyle.playableHintKey],
        AndroidContentStyle.listItemHintValue);
    expect(details.skip(1).map((item) => item.id),
        songs.map((song) => 'playlist/p1/playable/${song.id}'));
    expect(await handler.getMediaItem(details.first.id), details.first);
    expect(await handler.getMediaItem(details[1].id), details[1]);
    await handler.replaceQueue([registerSong()], autoPlay: false);
    await handler.playFromMediaId(details[2].id);
    expect(handler.queue.value.map((item) => item.id),
        songs.map((song) => song.id));
    expect(handler.mediaItem.value?.id, songs[1].id);
    verify(player.setUrl(songs[1].sourceUrl)).called(1);
  });

  test(
      'keeps cached playlist children including Shuffle after error and timeout',
      () async {
    final songs = [registerSong(), registerSong()];
    when(playableProvider.fetchForPlaylist('cached'))
        .thenAnswer((_) async => songs);
    final first = await handler.getChildren('playlist:cached');
    when(playableProvider.fetchForPlaylist('cached'))
        .thenThrow(Exception('offline'));
    expect(await handler.getChildren('playlist:cached'), first);
    when(playableProvider.fetchForPlaylist('cached'))
        .thenAnswer((_) => Completer<List<Playable>>().future);
    expect(await handler.getChildren('playlist:cached'), first);
  });

  test('does not repopulate playlist catalog or details after logout',
      () async {
    final catalogGate = Completer<void>();
    CapturingClient()
      ..willReturn(json: {
        'data': [
          {'id': 'old', 'name': 'Old', 'is_smart': false}
        ]
      }, waitFor: catalogGate.future)
      ..install();
    final song = registerSong();
    final detailsGate = Completer<List<Playable>>();
    when(playableProvider.fetchForPlaylist('old'))
        .thenAnswer((_) => detailsGate.future);
    final catalogRequest = handler.getChildren('playlists');
    final detailsRequest = handler.getChildren('playlist:old');
    await Future<void>.delayed(Duration.zero);
    await handler.cleanUpUponLogout();
    catalogGate.complete();
    detailsGate.complete([song]);
    expect(await catalogRequest, isEmpty);
    expect(await detailsRequest, isEmpty);
    expect(await handler.getMediaItem('playlist:old'), isNull);
    expect(
        await handler.getMediaItem('playlist/old/playable/${song.id}'), isNull);
    expect(await handler.getMediaItem('shuffle/playlist/old'), isNull);
  });

  test('shuffle plays an album end to end', () async {
    final songs = [registerSong(), registerSong()];
    when(playableProvider.fetchForAlbum('end-to-end'))
        .thenAnswer((_) async => songs);
    final children = await handler.getChildren('album:end-to-end');
    expect(children.first.id, 'shuffle/album/end-to-end');
    expect(children.first.playable, isTrue);
    expect(children.first.artUri.toString(),
        'android.resource://test.koel.sentinel/drawable/audio_service_shuffle');
    await handler.playFromMediaId(children.first.id);
    expect(
        handler.playbackState.value.shuffleMode, AudioServiceShuffleMode.all);
    verify(player.play()).called(1);
    await handler.skipToQueueItem(1);
    final current = handler.mediaItem.value?.id;
    await handler.setShuffleMode(AudioServiceShuffleMode.none);
    expect(handler.queue.value.map((item) => item.id),
        songs.map((song) => song.id));
    expect(handler.mediaItem.value?.id, current);
    when(playableProvider.fetchForAlbum('empty'))
        .thenAnswer((_) async => const []);
    expect(await handler.getChildren('album:empty'), isEmpty);
  });

  test('shuffle plays an artist end to end', () async {
    final songs = [registerSong(), registerSong()];
    when(playableProvider.fetchForArtist('end-to-end'))
        .thenAnswer((_) async => songs);
    final children = await handler.getChildren('artist:end-to-end');
    expect(children.first.id, 'shuffle/artist/end-to-end');
    expect(children.first.playable, isTrue);
    expect(children.first.artUri.toString(),
        'android.resource://test.koel.sentinel/drawable/audio_service_shuffle');
    expect(await handler.getMediaItem(children.first.id), children.first);
    await handler.playFromMediaId(children.first.id);
    expect(
        handler.playbackState.value.shuffleMode, AudioServiceShuffleMode.all);
    expect(queueIds(handler.queue.value),
        unorderedEquals(songs.map((song) => song.id)));
    verify(player.play()).called(1);
    when(playableProvider.fetchForArtist('empty'))
        .thenAnswer((_) async => const []);
    expect(await handler.getChildren('artist:empty'), isEmpty);
  });

  test(
      'regression playlist shuffle play is reversible and empty collections omit it',
      () async {
    final songs = [registerSong(), registerSong(), registerSong()];
    when(playableProvider.fetchForPlaylist('p1'))
        .thenAnswer((_) async => songs);
    final details = await handler.getChildren('playlist:p1');
    expect(details.first.id, 'shuffle/playlist/p1');
    expect(details.first.playable, isTrue);
    expect(details.first.artUri.toString(),
        'android.resource://test.koel.sentinel/drawable/audio_service_shuffle');
    await handler.playFromMediaId(details.first.id);
    expect(
        handler.playbackState.value.shuffleMode, AudioServiceShuffleMode.all);
    verify(player.play()).called(1);
    final shuffled = queueIds(handler.queue.value);
    await handler.setShuffleMode(AudioServiceShuffleMode.none);
    expect(queueIds(handler.queue.value), songs.map((song) => song.id));
    expect(shuffled, unorderedEquals(songs.map((song) => song.id)));
    when(playableProvider.fetchForPlaylist('empty'))
        .thenAnswer((_) async => const []);
    expect(await handler.getChildren('playlist:empty'), isEmpty);
  });
}

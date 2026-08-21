import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:app/app_state.dart';
import 'package:app/extensions/extensions.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/utils/api_request.dart';
import 'package:app/utils/features.dart';
import 'package:app/utils/preferences.dart' as preferences;
import 'package:app/values/queue_state.dart';
import 'package:audio_service/audio_service.dart';
import 'package:collection/collection.dart';
import 'package:just_audio/just_audio.dart';

class KoelAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  /// How many songs in a row may fail before playback gives up rather than
  /// keep skipping. Low, because the common cause of a run of failures is a
  /// dead connection, and each skip costs the user their place in the queue.
  static const MAX_ERROR_COUNT = 3;
  static const androidBrowsableRootExtras = {
    AndroidContentStyle.supportedKey: true,
  };
  static const _homeMediaId = 'home';
  static const _shuffleAction = 'shuffle';
  static const _homeMediaItem = MediaItem(
    id: _homeMediaId,
    title: 'Home',
    playable: false,
    extras: {
      AndroidContentStyle.browsableHintKey:
          AndroidContentStyle.gridItemHintValue,
    },
  );

  late final DownloadProvider downloadProvider;
  late final PlayableProvider playableProvider;
  late AudioServiceRepeatMode repeatMode;

  /// How long a source is given to become playable before we give up on it.
  /// Without this, a stalled connection leaves the player in `loading`
  /// indefinitely: neither just_audio nor the platform player time out on
  /// their own, so the future never completes and never throws.
  final Duration sourceLoadTimeout;
  final Duration browseLoadTimeout;

  var _browseGeneration = 0;
  var _errorCount = 0;
  var _initialized = false;
  var _queueRestored = false;
  var _switchingSource = false;
  var _currentMediaItem = MediaItem(id: '', title: '');
  var _isRadioMode = false;
  var _playbackFailed = false;
  AudioPlayer? _radioPlayer;
  StreamSubscription<List<MediaItem>>? _queueStateSubscription;
  StreamSubscription<Duration>? _playbackPositionSubscription;

  final AudioPlayer _player;
  final Random _random;
  final _overviewAlbums = <String, MediaItem>{};
  final _albumItems = <String, List<MediaItem>>{};
  final _albumPlayables = <String, List<Playable>>{};
  List<MediaItem>? _shuffleSnapshot;
  var _shuffleMode = AudioServiceShuffleMode.none;

  KoelAudioHandler({
    AudioPlayer? player,
    Random? random,
    this.sourceLoadTimeout = const Duration(seconds: 30),
    this.browseLoadTimeout = const Duration(seconds: 8),
  })  : _player = player ?? AudioPlayer(),
        _random = random ?? Random();

  AudioPlayer get player => _player;

  bool get isRadioMode => _isRadioMode;

  int get currentQueueIndex => queue.value.indexOf(_currentMediaItem);

  /// Initialize the audio handler with the required providers.
  /// Since the providers and preferences storage are not available at the time
  /// of construction, this method must be called before using the handler.
  init({
    required PlayableProvider playableProvider,
    required DownloadProvider downloadProvider,
  }) async {
    if (_initialized) return;

    _subscribeToPlayerPlaybackEvents();
    _subscribeToPlayerProcessingStateEvents();

    this
      ..downloadProvider = downloadProvider
      ..playableProvider = playableProvider
      ..repeatMode = preferences.repeatMode;

    _emitPlaybackState();
    await this.setVolume(preferences.volume);

    _initialized = true;
  }

  void enterRadioMode(AudioPlayer radioPlayer) {
    _isRadioMode = true;
    _radioPlayer = radioPlayer;
    radioPlayer.setVolume(preferences.volume);
  }

  void exitRadioMode() {
    _isRadioMode = false;
    _radioPlayer = null;
  }

  static List<MediaControl> radioControls({required bool playing}) {
    return [
      if (playing) MediaControl.pause else MediaControl.play,
    ];
  }

  void updateRadioPlaybackState({
    required bool playing,
    required AudioProcessingState processingState,
  }) {
    playbackState.add(PlaybackState(
      controls: radioControls(playing: playing),
      processingState: processingState,
      playing: playing,
    ));
  }

  void _subscribeToPlayerPlaybackEvents() {
    _player.playbackEventStream.listen(
      (_) => _emitPlaybackState(),
      onError: (_, __) => _abandonSource(),
    );
  }

  AudioProcessingState get _processingState {
    if (_playbackFailed) return AudioProcessingState.error;
    if (_isTransitioningPlayback) {
      return AudioProcessingState.loading;
    }

    return {
      // iOS 16+ seems to treat "idle" as "stopped" and close the audio
      // session, so we use "ready" to keep it alive.
      // @see https://stackoverflow.com/a/75236414
      ProcessingState.idle: Platform.isIOS
          ? AudioProcessingState.ready
          : AudioProcessingState.idle,
      ProcessingState.loading: AudioProcessingState.loading,
      ProcessingState.buffering: AudioProcessingState.buffering,
      ProcessingState.ready: AudioProcessingState.ready,
      ProcessingState.completed: AudioProcessingState.completed,
    }[_player.processingState]!;
  }

  bool get _hasContinuousPlayback {
    final index = currentQueueIndex;
    return index > -1 &&
        (index + 1 < queue.value.length ||
            repeatMode == AudioServiceRepeatMode.one ||
            repeatMode == AudioServiceRepeatMode.all);
  }

  bool get _isCompletingWithContinuation =>
      _hasContinuousPlayback &&
      _player.processingState == ProcessingState.completed;

  bool get _isTransitioningPlayback =>
      _switchingSource || _isCompletingWithContinuation;

  void _emitPlaybackState() {
    if (_isRadioMode) return;
    final playing = _isCompletingWithContinuation
        ? true
        : _switchingSource
            ? playbackState.value.playing
            : _player.playing;

    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
        MediaControl.custom(
          androidIcon: _shuffleMode == AudioServiceShuffleMode.all
              ? 'drawable/audio_service_shuffle_on'
              : 'drawable/audio_service_shuffle',
          label: _shuffleMode == AudioServiceShuffleMode.all
              ? 'Turn shuffle off'
              : 'Turn shuffle on',
          name: _shuffleAction,
        ),
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.playFromMediaId,
        MediaAction.skipToQueueItem,
        MediaAction.setShuffleMode,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: _processingState,
      repeatMode: repeatMode,
      shuffleMode: _shuffleMode,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: currentQueueIndex,
    ));
  }

  void _subscribeToPlayerProcessingStateEvents() {
    _player.processingStateStream.listen(
      (state) async {
        if (_isRadioMode) return;
        if (state == ProcessingState.completed) {
          if (repeatMode == AudioServiceRepeatMode.one) {
            await _player.seek(Duration.zero);
            await _player.play();
            return;
          }

          await skipToNext();
        }
      },
      // This stream is derived from the playback event stream, so it relays the
      // same errors. They are already turned into an error state there.
      onError: (_, __) {},
    );
  }

  Future<void> restoreQueue() async {
    if (_queueRestored || !Feature.queueStateSync.isSupported()) return;

    _queueRestored = true;
    await _trySetUpQueue();
  }

  Future<void> _trySetUpQueue() async {
    final state = AppState.get<QueueState>(['app', 'queueState'])!;

    if (state.playables.isEmpty) return;

    try {
      final playables = playableProvider.syncWithVault(state.playables);
      await replaceQueue(playables, shuffle: false, autoPlay: false);

      if (state.currentPlayable != null) {
        var currentPlayable =
            playableProvider.syncWithVault(state.currentPlayable).first;

        var queuedMediaItem = queue.value.firstWhereOrNull(
          (item) => item.id == currentPlayable.id,
        );

        if (queuedMediaItem != null) {
          try {
            await _setPlayerSource(queuedMediaItem).timeout(sourceLoadTimeout);
            await player.seek(Duration(seconds: state.playbackPosition));
          } catch (_) {
            await _abandonSource();
          }
        }
      }

      _queueStateSubscription = queue.stream.listen((mediaItems) {
        var playableIds = mediaItems.map((item) => item.id).toList();

        put('queue/state', data: {
          'songs': playableIds,
          'song': playableIds.isEmpty ? '' : _currentMediaItem.id,
        });
      });

      _playbackPositionSubscription = _player.positionStream
          .throttle(Duration(seconds: 1))
          .listen((position) {
        if (mediaItem.value == null || position.inSeconds % 5 != 0) return;

        put('queue/playback-status', data: {
          'song': _currentMediaItem.id,
          'position': position.inSeconds,
        });

        // if the playable is an episode, we want to keep track of the progress
        // in the app as well.
        if (_currentMediaItem.extras?['type'] == 'episode') {
          setPlaybackPositionToState(_currentMediaItem.id, position.inSeconds);
        }
      });
    } catch (e) {
      print(e);
    }
  }

  num? getPlaybackPositionFromState(String playableId) {
    return AppState.get<num>(['playbackPosition', playableId]);
  }

  void setPlaybackPositionToState(String playableId, num position) {
    AppState.set(['playbackPosition', playableId], position);
  }

  _setPlayerSource(MediaItem mediaItem) async {
    _playbackFailed = false;
    _switchingSource = true;
    _currentMediaItem = mediaItem;
    this.mediaItem.add(_currentMediaItem);
    _emitPlaybackState();

    try {
      final playable = playableProvider.byId(mediaItem.id)!;
      final download = downloadProvider.getForPlayable(playable);

      if (download == null) {
        await _player.setUrl(playable.sourceUrl);
      } else {
        await _player.setFilePath(download.path);
      }
      _switchingSource = false;
      _emitPlaybackState();
    } catch (error) {
      _switchingSource = false;
      rethrow;
    }
  }

  /// Tear down a source that stalled or errored, so the player is left in a
  /// state the user can retry or skip out of instead of a permanent spinner.
  Future<void> _abandonSource() async {
    _switchingSource = false;
    _playbackFailed = true;
    await _player.stop();
    _emitPlaybackState();
  }

  void _clearCurrentMediaItem() {
    _errorCount = 0;
    _switchingSource = false;
    _playbackFailed = false;
    _currentMediaItem = const MediaItem(id: '', title: '');
    mediaItem.add(null);
  }

  @override
  Future<List<MediaItem>> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? options,
  ]) async {
    if (parentMediaId == AudioService.browsableRootId) {
      return const [_homeMediaItem];
    }

    if (parentMediaId == _homeMediaId) {
      final browseGeneration = _browseGeneration;
      try {
        final response = await get('overview').timeout(browseLoadTimeout);
        if (browseGeneration != _browseGeneration) return const [];
        final albums = ((response['recently_added_albums'] ?? const []) as List)
            .map((entry) => Album.fromJson(entry as Map<String, dynamic>));
        final items = albums.map(_albumMediaItem).toList();
        _overviewAlbums
          ..clear()
          ..addEntries(items.map((item) => MapEntry(item.id, item)));
        return items;
      } catch (_) {
        return List.unmodifiable(_overviewAlbums.values);
      }
    }

    if (parentMediaId.startsWith('album:')) {
      final albumId = parentMediaId.substring('album:'.length);
      final browseGeneration = _browseGeneration;
      try {
        final playables = await playableProvider
            .fetchForAlbum(albumId)
            .timeout(browseLoadTimeout);
        final items = await Future.wait(playables.map((playable) async {
          final item = await playable.asMediaItem();
          return item.copyWith(
            id: _albumPlayableMediaId(albumId, playable.id),
          );
        }));
        if (browseGeneration != _browseGeneration) return const [];
        _albumItems[albumId] = List.unmodifiable(items);
        _albumPlayables[albumId] = List.unmodifiable(playables);
        return items;
      } catch (_) {
        return _albumItems[albumId] ?? const [];
      }
    }
    return const [];
  }

  String _albumPlayableMediaId(String albumId, String playableId) =>
      Uri(pathSegments: ['album', albumId, 'playable', playableId]).toString();

  MediaItem _albumMediaItem(Album album) {
    final artUri = album.cover == null ? null : Uri.tryParse(album.cover!);
    final hasRemoteArtwork =
        artUri?.scheme == 'http' || artUri?.scheme == 'https';

    return MediaItem(
      id: 'album:${album.id}',
      title: album.name,
      artist: album.artistName,
      artUri: hasRemoteArtwork ? artUri : null,
      playable: false,
      extras: {
        'type': 'album',
        'albumId': album.id.toString(),
        AndroidContentStyle.playableHintKey:
            AndroidContentStyle.listItemHintValue,
      },
    );
  }

  @override
  Future<MediaItem?> getMediaItem(String mediaId) async {
    return mediaId == _homeMediaId
        ? _homeMediaItem
        : _overviewAlbums[mediaId] ??
            queue.value.firstWhereOrNull((item) => item.id == mediaId) ??
            _albumItems.values
                .expand((items) => items)
                .firstWhereOrNull((item) => item.id == mediaId);
  }

  @override
  Future<void> playFromMediaId(
    String mediaId, [
    Map<String, dynamic>? extras,
  ]) async {
    final index = queue.value.indexWhere((item) => item.id == mediaId);
    if (index != -1) {
      await _playAtIndex(index);
      return;
    }

    final albumEntry = _albumItems.entries.firstWhereOrNull(
      (entry) => entry.value.any((item) => item.id == mediaId),
    );
    if (albumEntry == null) return;

    final selectedIndex =
        albumEntry.value.indexWhere((item) => item.id == mediaId);
    final albumPlayables = _albumPlayables[albumEntry.key];
    if (albumPlayables == null || selectedIndex >= albumPlayables.length)
      return;

    await replaceQueue(
      albumPlayables,
      shuffle: false,
      autoPlay: false,
    );
    await _playAtIndex(selectedIndex);
  }

  @override
  Future<void> skipToQueueItem(int index) => _playAtIndex(index);

  @override
  Future<dynamic> customAction(String name,
      [Map<String, dynamic>? extras]) async {
    if (name != _shuffleAction) return super.customAction(name, extras);

    await setShuffleMode(
      _shuffleMode == AudioServiceShuffleMode.all
          ? AudioServiceShuffleMode.none
          : AudioServiceShuffleMode.all,
    );
  }

  @override
  Future<void> play() async {
    if (_isRadioMode && _radioPlayer != null) {
      await _radioPlayer!.play();
      return;
    }

    // The player holds no usable source after a failed load, so pressing play
    // has to start the current item over rather than resume it.
    if (_playbackFailed && currentQueueIndex > -1) {
      return _playAtIndex(currentQueueIndex);
    }

    playbackState.add(playbackState.value.copyWith(playing: true));
    await _player.play();
  }

  @override
  Future<void> pause() async {
    if (_isRadioMode && _radioPlayer != null) {
      await _radioPlayer!.pause();
      return;
    }
    playbackState.add(playbackState.value.copyWith(playing: false));
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    if (_isRadioMode && _radioPlayer != null) {
      await _radioPlayer!.stop();
      exitRadioMode();
      playbackState.add(PlaybackState());
      return;
    }
    await _player.stop();
  }

  Future<void> queueAndPlay(Playable playable) async {
    await this.queueAfterCurrent(playable);
    await _playAtIndex(queue.value.indexOf(await playable.asMediaItem()));
  }

  Future<void> maybeQueueAndPlay(Playable playable, {position = 0}) async {
    if (await queued(playable)) {
      await _playAtIndex(queue.value.indexOf(await playable.asMediaItem()));
    } else {
      await queueAndPlay(playable);
    }
  }

  Future<void> queueAfterCurrent(Playable playable) async {
    _invalidateShuffleSnapshot();
    final mediaItem = await playable.asMediaItem();

    if (await queued(playable)) {
      await this.removeQueueItem(mediaItem);
    }

    await this.insertQueueItem(currentQueueIndex + 1, mediaItem);
    _emitPlaybackState();
  }

  Future<void> playOrPause() async {
    if (playbackState.value.playing) {
      await pause();
    } else {
      await play();
    }
  }

  @override
  Future<void> skipToNext() async {
    if (currentQueueIndex == -1) return;

    var nextIndex = currentQueueIndex + 1;

    if (nextIndex >= queue.value.length) {
      if (repeatMode == AudioServiceRepeatMode.all) {
        nextIndex = 0;
      } else {
        return;
      }
    }

    await _playAtIndex(nextIndex);
  }

  Future<void> _playAtIndex(int index) async {
    if (index < 0 || queue.value.length <= index) return;

    final mediaItem = queue.value[index];
    final position = getPlaybackPositionFromState(mediaItem.id) ?? 0;

    try {
      await _setPlayerSource(mediaItem).timeout(sourceLoadTimeout);
      _errorCount = 0;
      exitRadioMode();
      await _player.seek(Duration(seconds: position.toInt()));
      await play();
      _emitPlaybackState();

      put('queue/playback-status', data: {
        'song': mediaItem.id,
        'position': _player.position.inSeconds,
      });
    } catch (error) {
      _errorCount++;
      await _abandonSource();

      if (_shouldSkipPast(error)) await skipToNext();
    }
  }

  /// A stalled load means the connection is at fault, not the song, and the
  /// next one would stall just the same. Every other failure belongs to this
  /// song alone, so move past it — but a run of them is something systematic
  /// that churning through the queue would only hide.
  bool _shouldSkipPast(Object error) =>
      error is! TimeoutException && _errorCount < MAX_ERROR_COUNT;

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToPrevious() async {
    if (_player.position > Duration(seconds: 5))
      return _player.seek(Duration.zero);

    if (currentQueueIndex == -1) return;

    var previousIndex = currentQueueIndex - 1;

    if (previousIndex < 0) {
      if (repeatMode == AudioServiceRepeatMode.all) {
        previousIndex = queue.value.length - 1;
      } else {
        return;
      }
    }

    await _playAtIndex(previousIndex);
  }

  Future<bool> queued(Playable playable) async =>
      queue.value.contains(await playable.asMediaItem());

  @override
  Future<void> removeQueueItemAt(int index) async {
    if (index < 0 || index >= queue.value.length) return;

    _invalidateShuffleSnapshot();
    if (index == currentQueueIndex) {
      final hasNextItem = index + 1 < queue.value.length;
      final wrapsToStart =
          repeatMode == AudioServiceRepeatMode.all && queue.value.length > 1;
      if (hasNextItem || wrapsToStart) {
        await skipToNext();
      } else {
        await _player.stop();
        _clearCurrentMediaItem();
      }
    }

    queue.value.removeAt(index);
    queue.add(queue.value);
    _emitPlaybackState();
  }

  void moveQueueItem(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= queue.value.length ||
        newIndex < 0 ||
        newIndex > queue.value.length) {
      return;
    }

    _invalidateShuffleSnapshot();
    if (oldIndex < newIndex) newIndex -= 1;

    final item = queue.value.removeAt(oldIndex);
    queue.value.insert(newIndex, item);
    queue.add(queue.value);
    _emitPlaybackState();
  }

  Future<void> clearQueue() async {
    _invalidateShuffleSnapshot();
    await updateQueue([]);
    _emitPlaybackState();
  }

  void _invalidateShuffleSnapshot() {
    if (_shuffleSnapshot == null &&
        _shuffleMode == AudioServiceShuffleMode.none) {
      return;
    }

    _shuffleSnapshot = null;
    _shuffleMode = AudioServiceShuffleMode.none;
    _emitPlaybackState();
  }

  Future<void> setVolume(double value) async {
    await _player.setVolume(value);
    await _radioPlayer?.setVolume(value);
  }

  Future<void> replaceQueue(
    List<Playable> playables, {
    bool shuffle = false,
    bool autoPlay = true,
  }) async {
    final items = await Future.wait(playables.map((p) => p.asMediaItem()));
    _shuffleSnapshot = shuffle ? List.unmodifiable(items) : null;
    _shuffleMode =
        shuffle ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none;
    final orderedItems = List<MediaItem>.from(items);
    if (shuffle) orderedItems.shuffle(_random);

    await updateQueue(orderedItems);
    _emitPlaybackState();

    if (autoPlay) {
      await _playAtIndex(0);
    }
  }

  void _shuffleItems(List<MediaItem> items) {
    final currentId = _currentMediaItem.id;
    final currentIndex = items.indexWhere((item) => item.id == currentId);
    if (currentIndex > -1) {
      final current = items.removeAt(currentIndex);
      items.shuffle(_random);
      items.insert(0, current);
    } else {
      items.shuffle(_random);
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode mode) async {
    if (mode == AudioServiceShuffleMode.all) {
      _shuffleSnapshot ??= List.unmodifiable(queue.value);
      final shuffled = List<MediaItem>.from(_shuffleSnapshot!);
      _shuffleItems(shuffled);
      _shuffleMode = AudioServiceShuffleMode.all;
      await updateQueue(shuffled);
    } else {
      final snapshot = _shuffleSnapshot;
      if (snapshot != null) {
        await updateQueue(List<MediaItem>.from(snapshot));
      }
      _shuffleSnapshot = null;
      _shuffleMode = AudioServiceShuffleMode.none;
    }
    _emitPlaybackState();
  }

  Future<AudioServiceRepeatMode> rotateRepeatMode() async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        repeatMode = AudioServiceRepeatMode.all;
        break;
      case AudioServiceRepeatMode.all:
        repeatMode = AudioServiceRepeatMode.one;
        break;
      default:
        repeatMode = AudioServiceRepeatMode.none;
        break;
    }

    preferences.repeatMode = repeatMode;
    await this.setRepeatMode(repeatMode);

    return repeatMode;
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
    // Only pass LoopMode.one to the player for gapless single-track repeat.
    // "Repeat all" is handled by the app's own queue logic in skipToNext().
    await _player.setLoopMode(
      repeatMode == AudioServiceRepeatMode.one ? LoopMode.one : LoopMode.off,
    );
  }

  Future<void> cleanUpUponLogout() async {
    _browseGeneration++;
    await _queueStateSubscription?.cancel();
    await _playbackPositionSubscription?.cancel();
    _queueStateSubscription = null;
    _playbackPositionSubscription = null;
    await stop();
    _queueRestored = false;
    _overviewAlbums.clear();
    _albumItems.clear();
    _albumPlayables.clear();
    _clearCurrentMediaItem();
    await clearQueue();
  }

  Future<void> queueToBottom(Playable playable) async {
    _invalidateShuffleSnapshot();
    final mediaItem = await playable.asMediaItem();

    if (await queued(playable)) {
      await removeQueueItem(mediaItem);
    }

    await addQueueItem(mediaItem);
    _emitPlaybackState();
  }

  Future<void> removeFromQueue(Playable playable) async {
    final index = queue.value.indexOf(await playable.asMediaItem());
    if (index != -1) await removeQueueItemAt(index);
  }
}

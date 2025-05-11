import 'dart:io';

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
  static const MAX_ERROR_COUNT = 10;

  late final DownloadProvider downloadProvider;
  late final PlayableProvider playableProvider;
  late AudioServiceRepeatMode repeatMode;

  var _errorCount = 0;
  var _initialized = false;
  var _currentMediaItem = MediaItem(id: '', title: '');

  final _player = AudioPlayer();

  AudioPlayer get player => _player;

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

    await this.setVolume(preferences.volume);

    if (Feature.queueStateSync.isSupported()) {
      _trySetUpQueue();
    }

    _initialized = true;
  }

  void _subscribeToPlayerPlaybackEvents() {
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: {
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
        }[_player.processingState]!,
        repeatMode: repeatMode,
        shuffleMode: _player.shuffleModeEnabled
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: currentQueueIndex,
      ));
    });
  }

  void _subscribeToPlayerProcessingStateEvents() {
    _player.processingStateStream.listen((state) async {
      if (state == ProcessingState.completed) {
        if (repeatMode == AudioServiceRepeatMode.one) {
          await _player.seek(Duration.zero);
          await _player.play();
          return;
        }

        await skipToNext();
      }
    });
  }

  void _trySetUpQueue() async {
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
          _setPlayerSource(queuedMediaItem);
          player.seek(Duration(seconds: state.playbackPosition));
        }
      }

      queue.stream.listen((mediaItems) {
        var playableIds = mediaItems.map((item) => item.id).toList();
        if (playableIds.isEmpty) return;

        put('queue/state', data: {
          'songs': playableIds,
          'song': _currentMediaItem.id,
        });
      });

      _player.positionStream.throttle(Duration(seconds: 1)).listen((position) {
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
    _currentMediaItem = mediaItem;
    this.mediaItem.add(_currentMediaItem);

    final playable = playableProvider.byId(mediaItem.id)!;
    final download = downloadProvider.getForPlayable(playable);

    if (download == null) {
      await _player.setUrl(mediaItem.extras?['sourceUrl'] as String);
    } else {
      await _player.setFilePath(download.path);
    }
  }

  @override
  Future<void> play() async {
    playbackState.add(playbackState.value.copyWith(playing: true));
    await _player.play();
  }

  @override
  Future<void> pause() async {
    playbackState.add(playbackState.value.copyWith(playing: false));
    await _player.pause();
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
    final mediaItem = await playable.asMediaItem();

    if (await queued(playable)) {
      await this.removeQueueItem(mediaItem);
    }

    await this.insertQueueItem(currentQueueIndex + 1, mediaItem);
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
    if (queue.value.length <= index) return;

    final mediaItem = queue.value[index];
    final position = getPlaybackPositionFromState(mediaItem.id) ?? 0;

    try {
      await _setPlayerSource(mediaItem);
      _player.seek(Duration(seconds: position.toInt()));
      await play();

      put('queue/playback-status', data: {
        'song': mediaItem.id,
        'position': _player.position.inSeconds,
      });

      // Reset the error count if the song is successfully loaded.
      _errorCount = 0;
    } catch (e) {
      _errorCount++;
    }
  }

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
    if (index == currentQueueIndex) await skipToNext();

    if (index >= queue.value.length) return;

    queue.value.removeAt(index);
    queue.add(queue.value);
  }

  void moveQueueItem(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;

    final item = queue.value.removeAt(oldIndex);
    queue.value.insert(newIndex, item);
    queue.add(queue.value);
  }

  Future<void> clearQueue() async {
    await updateQueue([]);
  }

  Future<void> setVolume(double value) async => await _player.setVolume(value);

  Future<void> replaceQueue(
    List<Playable> playables, {
    bool shuffle = false,
    bool autoPlay = true,
  }) async {
    final items = await Future.wait(playables.map((p) => p.asMediaItem()));
    if (shuffle) items.shuffle();

    await updateQueue(items);

    if (autoPlay) {
      await _playAtIndex(0);
    }
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
    await _player.setLoopMode(LoopMode.values[repeatMode.index]);
  }

  Future<void> cleanUpUponLogout() async {
    await _player.stop();
    await clearQueue();
  }

  Future<void> queueToBottom(Playable playable) async {
    final mediaItem = await playable.asMediaItem();

    if (await queued(playable)) {
      await removeQueueItem(mediaItem);
    }

    await addQueueItem(mediaItem);
  }

  Future<void> removeFromQueue(Playable playable) async {
    if (await queued(playable)) {
      await removeQueueItem(await playable.asMediaItem());
    }
  }
}

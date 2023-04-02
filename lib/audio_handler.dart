import 'dart:io';

import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:app/utils/preferences.dart' as preferences;

class KoelAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  static const MAX_ERROR_COUNT = 10;

  late final DownloadProvider downloadProvider;
  late final SongProvider songProvider;
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
    required SongProvider songProvider,
    required DownloadProvider downloadProvider,
  }) async {
    if (_initialized) return;

    _subscribeToPlayerPlaybackEvents();
    _subscribeToPlayerProcessingStateEvents();

    this
      ..downloadProvider = downloadProvider
      ..songProvider = songProvider
      ..repeatMode = preferences.repeatMode
      ..setVolume(preferences.volume);

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
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        if (repeatMode == AudioServiceRepeatMode.one) {
          _player.seek(Duration.zero);
          _player.play();
          return;
        }

        skipToNext();
      }
    });
  }

  _setPlayerSource(MediaItem mediaItem) async {
    _currentMediaItem = mediaItem;
    final song = songProvider.byId(mediaItem.id)!;
    final download = downloadProvider.getForSong(song);

    if (download == null) {
      await _player.setUrl(mediaItem.extras?['sourceUrl'] as String);
    } else {
      await _player.setFilePath(download.file.path);
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

  Future<void> queueAndPlay(Song song) async {
    await this.queueAfterCurrent(song);
    await _playAtIndex(queue.value.indexOf(song.mediaItem));
  }

  Future<void> queueAfterCurrent(Song song) async {
    if (queued(song)) return;
    await this.insertQueueItem(currentQueueIndex + 1, song.mediaItem);
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
    this.mediaItem.add(mediaItem);

    try {
      await _setPlayerSource(mediaItem);
      await play();

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

  queued(Song song) => queue.value.contains(song.mediaItem);

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

  clearQueue() async {
    await updateQueue([]);
  }

  void setVolume(double value) => _player.setVolume(value);

  Future<void> replaceQueue(List<Song> songs, {bool shuffle = false}) async {
    final items = songs.map((song) => song.mediaItem).toList();
    if (shuffle) items.shuffle();

    updateQueue(items);

    await _playAtIndex(0);
  }

  AudioServiceRepeatMode rotateRepeatMode() {
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
    this.setRepeatMode(repeatMode);

    return repeatMode;
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
    await _player.setLoopMode(LoopMode.values[repeatMode.index]);
  }

  Future<void> cleanUpUponLogout() async {
    await _player.stop();
    clearQueue();
  }

  void queueToBottom(Song song) {
    if (queued(song)) {
      removeQueueItem(song.mediaItem);
    }

    addQueueItem(song.mediaItem);
  }

  void removeFromQueue(Song song) {
    if (queued(song)) {
      removeQueueItem(song.mediaItem);
    }
  }
}

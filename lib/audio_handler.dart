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

  KoelAudioHandler() {
    _subscribeToPlayerPlaybackEvents();
    _subscribeToPlayerProcessingStateEvents();
  }

  /// Initialize the audio handler with the required providers.
  /// Since the providers and preferences storage are not available at the time
  /// of construction, this method must be called before using the handler.
  void init({
    required SongProvider songProvider,
    required DownloadProvider downloadProvider,
  }) {
    if (_initialized) return;

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
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        repeatMode: const {
          LoopMode.off: AudioServiceRepeatMode.none,
          LoopMode.one: AudioServiceRepeatMode.one,
          LoopMode.all: AudioServiceRepeatMode.all,
        }[_player.loopMode]!,
        shuffleMode: _player.shuffleModeEnabled
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
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
  skipToNext() async {
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
    } catch (e) {
      _errorCount++;
    }

    // Reset the error count if the song is successfully loaded.
  }

  @override
  skipToPrevious() async {
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

  Future<void> maybeSkipToPrevious() async {
    if (_player.position > Duration(seconds: 5)) {
      await _player.seek(Duration.zero);
    } else {
      await skipToPrevious();
    }
  }

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

  void clearQueue() {
    queue.value.clear();
    queue.add(queue.value);
  }

  void setVolume(double value) => _player.setVolume(value);

  Future<void> replaceQueue(List<Song> songs, {bool shuffle = false}) async {
    final items = songs.map((song) => song.mediaItem).toList();
    if (shuffle) items.shuffle();
    queue.value = items;
    queue.add(queue.value);
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

    return repeatMode;
  }

  Future<void> cleanUpUponLogout() async {
    await _player.stop();
    queue.value.clear();
    queue.add(queue.value);
  }

  void queueToBottom(Song song) {
    if (queued(song)) {
      queue.value.remove(song.mediaItem);
    }

    queue.value.add(song.mediaItem);
    queue.add(queue.value);
  }

  void removeFromQueue(Song song) {
    if (queued(song)) {
      queue.value.remove(song.mediaItem);
      queue.add(queue.value);
    }
  }
}

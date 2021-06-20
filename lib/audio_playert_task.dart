import 'dart:async';

import 'package:app/utils/preferences.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerTask extends BackgroundAudioTask {
  final MediaLibrary _mediaLibrary = MediaLibrary();
  AudioPlayer _player = new AudioPlayer();
  AudioProcessingState? _skipState;
  late StreamSubscription<PlaybackEvent> _eventSubscription;

  late ConcatenatingAudioSource _audioSource;

  List<MediaItem> get queue => _mediaLibrary.items;

  int? get currentIndex => _player.currentIndex;

  MediaItem? get currentMediaItem =>
      currentIndex == null ? null : queue[currentIndex!];

  @override
  Future<void> onStart(Map<String, dynamic>? params) async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music());

    _player.currentIndexStream.listen((index) {
      if (index != null) {
        AudioServiceBackground.setMediaItem(queue[index]);
      }
    });

    _eventSubscription = _player.playbackEventStream.listen((event) {
      _broadcastState();
    });

    _player.processingStateStream.listen((state) async {
      switch (state) {
        case ProcessingState.completed:
          await onStop();
          break;
        case ProcessingState.ready:
          // If we just came from skipping between tracks, clear the skip
          // state now that we're ready to play.
          _skipState = null;
          break;
        default:
          break;
      }
    });

    // Load and broadcast the queue
    AudioServiceBackground.setQueue(queue);
    Preferences prefs = new Preferences();
    String hostUri = (await prefs.getHostUrl())!;
    String apiToken = (await prefs.getApiToken())!;

    try {
      _audioSource = ConcatenatingAudioSource(
        children: queue.map((item) {
          return AudioSource.uri(
              Uri.parse("$hostUri/play/${item.id}?api_token=$apiToken"));
        }).toList(),
      );

      await _player.setAudioSource(_audioSource);
      // In this example, we automatically start playing on start.
      onPlay();
    } catch (e) {
      print("Error: $e");
      onStop();
    }
  }

  @override
  Future<dynamic> onCustomAction(String name, arguments) async {
    switch (name) {
      case 'playNow':
        await onPlayFromMediaId(arguments as String);
        return;
      default:
        return;
    }
  }

  @override
  Future<void> onPlayFromMediaId(String mediaId) async {
    await _player.setUrl(mediaId);
    await _player.play();
  }

  @override
  Future<void> onAddQueueItem(MediaItem mediaItem) async {
    queue.add(mediaItem);
    _audioSource.add(AudioSource.uri(Uri.parse(mediaItem.id)));
  }

  @override
  Future<void> onAddQueueItemAt(MediaItem mediaItem, int index) async {
    queue.insert(index, mediaItem);
    _audioSource.insert(index, AudioSource.uri(Uri.parse(mediaItem.id)));
  }

  @override
  Future<void> onRemoveQueueItem(MediaItem mediaItem) async {
    int index = queue.indexOf(mediaItem);
    queue.remove(mediaItem);
    _audioSource.removeAt(index);
  }

  @override
  Future<void> onSkipToQueueItem(String mediaId) async {
    // Then default implementations of onSkipToNext and onSkipToPrevious will
    // delegate to this method.
    final newIndex = queue.indexWhere((item) => item.id == mediaId);
    if (newIndex == -1) return;
    // During a skip, the player may enter the buffering state. We could just
    // propagate that state directly to AudioService clients but AudioService
    // has some more specific states we could use for skipping to next and
    // previous. This variable holds the preferred state to send instead of
    // buffering during a skip, and it is cleared as soon as the player exits
    // buffering (see the listener in onStart).
    _skipState = newIndex > currentIndex!
        ? AudioProcessingState.skippingToNext
        : AudioProcessingState.skippingToPrevious;
    // This jumps to the beginning of the queue item at newIndex.
    _player.seek(Duration.zero, index: newIndex);
    // Demonstrate custom events.
    AudioServiceBackground.sendCustomEvent('skip to $newIndex');
  }

  @override
  Future<void> onPlay() async {
    _player.play();
  }

  @override
  Future<void> onPause() => _player.pause();

  @override
  Future<void> onSeekTo(Duration position) => _player.seek(position);

  @override
  Future<void> onSkipToNext() => _player.seekToNext();

  // @override
  // Future<void> onStop() async {
  //   // await _player.dispose();
  //   // _eventSubscription.cancel();
  //   // // It is important to wait for this state to be broadcast before we shut
  //   // // down the task. If we don't, the background task will be destroyed before
  //   // // the message gets sent to the UI.
  //   // await _broadcastState();
  //   // // Shut down this task
  //   await super.onStop();
  // }

  /// Broadcasts the current state to all clients.
  Future<void> _broadcastState() async {
    await AudioServiceBackground.setState(
      controls: [
        MediaControl.skipToPrevious,
        _player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: [
        MediaAction.seekTo,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      ],
      androidCompactActions: [0, 1, 3],
      processingState: _getProcessingState(),
      playing: _player.playing,
      position: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    );
  }

  /// Maps just_audio's processing state into into audio_service's playing
  /// state. If we are in the middle of a skip, we use [_skipState] instead.
  AudioProcessingState _getProcessingState() {
    if (_skipState != null) return _skipState!;
    switch (_player.processingState) {
      case ProcessingState.idle:
        return AudioProcessingState.stopped;
      case ProcessingState.loading:
        return AudioProcessingState.connecting;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
      default:
        throw Exception("Invalid state: ${_player.processingState}");
    }
  }
}

class MediaLibrary {
  late final Map<String, dynamic> _extras;
  late final List<MediaItem> _items;

  MediaLibrary() {
    _extras = new Map();
    _extras['songId'] = 'd7fc91319f9ba814b74e312a7df745eb';
    _items = <MediaItem>[
      MediaItem(
        id: 'd7fc91319f9ba814b74e312a7df745eb',
        album: 'Made in Haven',
        title: 'Yeah',
        artist: 'Queen',
        artUri: Uri.parse(
            'https://lastfm.freetls.fastly.net/i/u/300x300/3c32fca5ea6c4788959ee4f7013c6fd'),
        extras: this._extras,
      ),
    ];
  }

  List<MediaItem> get items => _items;
}

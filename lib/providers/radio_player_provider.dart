import 'dart:async';

import 'package:app/main.dart';
import 'package:app/models/models.dart';
import 'package:app/utils/api_request.dart' as api;
import 'package:app/utils/preferences.dart' as preferences;
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

const _pollInterval = Duration(seconds: 15);

class RadioPlayerProvider with ChangeNotifier {
  final _player = AudioPlayer();
  RadioStation? _currentStation;
  var _playing = false;
  var _loading = false;
  String? _streamTitle;
  Timer? _nowPlayingTimer;

  StreamSubscription? _playingSubscription;
  StreamSubscription? _processingSubscription;
  StreamSubscription? _queuePlaybackSubscription;

  RadioStation? get currentStation => _currentStation;
  bool get playing => _playing;
  bool get loading => _loading;
  bool get active => _currentStation != null;
  String? get streamTitle => _streamTitle;

  RadioPlayerProvider() {
    _playingSubscription = _player.playingStream.listen((playing) {
      _playing = playing;
      if (active && audioHandler.isRadioMode) {
        audioHandler.updateRadioPlaybackState(
          playing: playing,
          processingState: _loading
              ? AudioProcessingState.buffering
              : AudioProcessingState.ready,
        );
      }
      notifyListeners();
    });

    _processingSubscription =
        _player.processingStateStream.listen((state) {
      _loading = state == ProcessingState.loading ||
          state == ProcessingState.buffering;
      if (active && audioHandler.isRadioMode) {
        audioHandler.updateRadioPlaybackState(
          playing: _playing,
          processingState: const {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[state]!,
        );
      }
      notifyListeners();
    });

    // When queue playback starts, stop radio
    _queuePlaybackSubscription =
        audioHandler.playbackState.listen((state) {
      if (state.playing && active && !audioHandler.isRadioMode) {
        stop();
      }
    });
  }

  static MediaItem mediaItemForStation(
    RadioStation station, {
    String? streamTitle,
  }) {
    return MediaItem(
      id: 'radio-${station.id}',
      title: streamTitle ?? station.name,
      artist: streamTitle != null ? station.name : 'Radio',
      artUri: station.logo != null ? Uri.tryParse(station.logo!) : null,
    );
  }

  Future<void> play(RadioStation station) async {
    // Pause the main queue player before entering radio mode
    if (audioHandler.playbackState.value.playing) {
      await audioHandler.pause();
    }

    audioHandler.enterRadioMode(_player);

    _currentStation = station;
    _streamTitle = null;
    _loading = true;
    notifyListeners();

    // Push radio station info to the OS media session
    audioHandler.mediaItem.add(mediaItemForStation(station));

    final streamUrl =
        '${preferences.host}/radio/stream/${station.id}?t=${preferences.audioToken}';

    try {
      await _player.setUrl(streamUrl);
      await _player.play();
      // Delay the first poll briefly to let the playing state propagate
      // so the UI is ready to display the stream title.
      Future.delayed(const Duration(seconds: 2), () {
        if (active && _currentStation?.id == station.id) {
          _startNowPlayingPolling(station);
        }
      });
    } catch (e) {
      _currentStation = null;
      _loading = false;
      audioHandler.exitRadioMode();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> stop() async {
    _stopNowPlayingPolling();
    await _player.stop();
    _currentStation = null;
    _playing = false;
    _loading = false;
    _streamTitle = null;
    audioHandler.exitRadioMode();
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_playing) {
      await _player.pause();
    } else if (_currentStation != null) {
      await _player.play();
    }
  }

  void _startNowPlayingPolling(RadioStation station) {
    _stopNowPlayingPolling();
    _fetchNowPlaying(station);
    _nowPlayingTimer = Timer.periodic(_pollInterval, (_) {
      _fetchNowPlaying(station);
    });
  }

  void _stopNowPlayingPolling() {
    _nowPlayingTimer?.cancel();
    _nowPlayingTimer = null;
  }

  Future<void> _fetchNowPlaying(RadioStation station) async {
    try {
      final response =
          await api.get('radio/stations/${station.id}/now-playing');
      final title = response?['stream_title'] as String?;

      if (!active || _currentStation?.id != station.id) return;

      if (title != _streamTitle) {
        _streamTitle = title;
        audioHandler.mediaItem.add(mediaItemForStation(
          station,
          streamTitle: title,
        ));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to fetch now-playing metadata: $e');
    }
  }

  @override
  void dispose() {
    _stopNowPlayingPolling();
    _playingSubscription?.cancel();
    _processingSubscription?.cancel();
    _queuePlaybackSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }
}

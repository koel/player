import 'dart:async';

import 'package:app/main.dart';
import 'package:app/models/models.dart';
import 'package:app/utils/preferences.dart' as preferences;
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class RadioPlayerProvider with ChangeNotifier {
  final _player = AudioPlayer();
  RadioStation? _currentStation;
  var _playing = false;
  var _loading = false;
  String? _streamTitle;

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
      notifyListeners();
    });

    _processingSubscription =
        _player.processingStateStream.listen((state) {
      _loading = state == ProcessingState.loading ||
          state == ProcessingState.buffering;
      notifyListeners();
    });

    // When queue playback starts, stop radio
    _queuePlaybackSubscription =
        audioHandler.playbackState.listen((state) {
      if (state.playing && active) {
        stop();
      }
    });
  }

  Future<void> play(RadioStation station) async {
    // Pause the main queue player when radio starts
    if (audioHandler.playbackState.value.playing) {
      await audioHandler.pause();
    }

    _currentStation = station;
    _streamTitle = null;
    _loading = true;
    notifyListeners();

    final streamUrl =
        '${preferences.host}/radio/stream/${station.id}?t=${preferences.audioToken}';

    try {
      await _player.setUrl(streamUrl);
      await _player.play();
    } catch (e) {
      _currentStation = null;
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _currentStation = null;
    _playing = false;
    _loading = false;
    _streamTitle = null;
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_playing) {
      await _player.pause();
    } else if (_currentStation != null) {
      await _player.play();
    }
  }

  void updateStreamTitle(String? title) {
    if (title != _streamTitle) {
      _streamTitle = title;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _playingSubscription?.cancel();
    _processingSubscription?.cancel();
    _queuePlaybackSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }
}

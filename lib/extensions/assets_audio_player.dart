import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/foundation.dart';

extension AssetsAudioPlayerExtension on AssetsAudioPlayer {
  static String? _songId;

  Future<void> restart() async {
    this.seek(new Duration(seconds: 0), force: true);
  }

  String? get songId => _songId ?? getCurrentAudioextra['songId'];

  @visibleForTesting
  void setSongId(String id) => _songId = id;
}

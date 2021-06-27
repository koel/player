import 'package:assets_audio_player/assets_audio_player.dart';

extension AssetsAudioPlayerExtension on AssetsAudioPlayer {
  Future<void> restart() async {
    this.seek(new Duration(seconds: 0), force: true);
  }
}

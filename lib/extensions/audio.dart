import 'package:assets_audio_player/assets_audio_player.dart';

extension AudioExtension on Audio {
  String? get songId => metas.extra?['songId'];
}

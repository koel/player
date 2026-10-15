import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';

class QueueState {
  List<Playable> playables;
  Playable? currentPlayable;
  int playbackPosition;

  QueueState({
    required this.playables,
    this.currentPlayable,
    this.playbackPosition = 0,
  });

  static parse(Map<String, dynamic> json, PlayableProvider playableProvider) {
    final playables = playableProvider.parseFromJson(json['songs']);

    var currentPlayable = json['current_song'] != null
        ? Playable.tryFromJson(json['current_song'])
        : null;

    return QueueState(
      playables: playables,
      currentPlayable: currentPlayable,
      playbackPosition: json['playback_position'],
    );
  }

  static empty() {
    return QueueState(
      playables: [],
      currentPlayable: null,
      playbackPosition: 0,
    );
  }
}

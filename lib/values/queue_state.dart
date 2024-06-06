import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';

class QueueState {
  List<Song> songs;
  Song? currentSong;
  int playbackPosition;

  QueueState({
    required this.songs,
    this.currentSong,
    this.playbackPosition = 0,
  });

  static parse(Map<String, dynamic> json, SongProvider songProvider) {
    final songs = songProvider.parseFromJson(json['songs']);

    var currentSong =
        json['current_song'] != null && json['current_song']['type'] == 'songs'
            ? Song.fromJson(json['current_song'])
            : null;

    return QueueState(
      songs: songs,
      currentSong: currentSong,
      playbackPosition: json['playback_position'],
    );
  }

  static empty() {
    return QueueState(
      songs: [],
      currentSong: null,
      playbackPosition: 0,
    );
  }
}

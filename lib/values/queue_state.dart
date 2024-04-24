import 'package:app/models/models.dart';

class QueueState {
  List<Song> songs;
  Song? currentSong;
  int playbackPosition;

  QueueState({
    required this.songs,
    this.currentSong,
    this.playbackPosition = 0,
  });

  static parse(Map<String, dynamic> json) {
    return QueueState(
      songs: (json['songs'] as List<dynamic>)
          .map<Song>((song) => Song.fromJson(song))
          .toList(),
      currentSong: json['current_song'] != null
          ? Song.fromJson(json['current_song'])
          : null,
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

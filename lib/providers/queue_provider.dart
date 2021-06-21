import 'package:app/models/song.dart';
import 'package:app/utils/preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class QueueProvider with ChangeNotifier {
  final ConcatenatingAudioSource _audioSource = ConcatenatingAudioSource(
    children: [],
  );

  final List<Song> _songs = <Song>[];

  void addToTop(Song song) async {
    _songs.insert(0, song);
    _audioSource.insert(0, await songToAudioSource(song));
  }

  void addToBottom(Song song) async {
    _songs.add(song);
    _audioSource.add(await songToAudioSource(song));
  }

  Future<UriAudioSource> songToAudioSource(Song song) async {
    return AudioSource.uri(
      Uri.parse("${await hostUrl}/play/${song.id}?api_token=${await apiToken}"),
    );
  }

  List<Song> get songs {
    return _songs;
  }

  ConcatenatingAudioSource get audioSource => _audioSource;
}

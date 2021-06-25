import 'package:app/models/song.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/foundation.dart';

class AudioPlayerProvider with ChangeNotifier {
  late AssetsAudioPlayer _player;
  late Playlist _queue;

  Future<void> init() async {
    _player = AssetsAudioPlayer.newPlayer();

    _queue = Playlist(
      audios: <Audio>[
        // Set a blank audio to ensure the playlist is initialized
        // (Assets Audio Player will set playlist to NULL if the list is empty).
        Audio('assets/audio/blank.mp3'),
      ],
      startIndex: 0,
    );

    await _player.open(
      _queue,
      showNotification: true,
      autoStart: false,
    );
  }

  Future<void> play() async => await _player.play();
  Future<void> stop() async => await _player.stop();

  Future<void> queueToBottom(Song song) async {
    _queue.add(await song.asAudio());
  }

  Future<void> replaceQueue(List<Song> songs, { shuffle = false }) async {
    List<Audio> audios = await Future.wait(
      songs.map((song) async => await song.asAudio()),
    );

    if (shuffle) {
      audios.shuffle();
    }

    _player.playlist?.audios.clear();

    await _player.stop();
    audios.forEach((audio) => _player.playlist?.add(audio));
    _player.play();
  }

  AssetsAudioPlayer get player => _player;

  Playlist get queue => _queue;
}

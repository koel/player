import 'package:app/models/song.dart';
import 'package:app/providers/song_provider.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AudioPlayerProvider with ChangeNotifier {
  late AssetsAudioPlayer _player;
  late Playlist _queue;
  Audio? _currentAudio;

  Future<void> init() async {
    _player = AssetsAudioPlayer.newPlayer();

    _player.current.listen((Playing? playing) {
      _currentAudio = playing?.audio.audio;
    });

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

  Future<bool> queued(Song song) async => await indexInQueue(song) != -1;

  Future<int> indexInQueue(Song song) async {
    return _player.playlist!.audios.indexOf(await song.asAudio());
  }

  Future<int> queueAfterCurrent(Song song) async {
    Audio audio = await song.asAudio();
    int index = _player.playlist!.audios.indexOf(_currentAudio!) + 1;
    _player.playlist!.insert(index, audio);

    return index;
  }

  Future<void> play({Song? song}) async {
    if (song == null) {
      return await _player.play();
    }

    int index = await indexInQueue(song);

    if (index != -1) {
      await _player.playlistPlayAtIndex(index);
    } else {
      await _player.playlistPlayAtIndex(
        _currentAudio == null
            ? await queueToTop(song)
            : await queueAfterCurrent(song),
      );
    }

    await _player.play();
  }

  Future<void> stop() async => await _player.stop();

  Future<int> queueToTop(Song song) async {
    _player.playlist!.insert(0, await song.asAudio());
    return 0;
  }

  Future<int> queueToBottom(Song song) async {
    _player.playlist!.add(await song.asAudio());
    return _player.playlist!.numberOfItems;
  }

  Future<void> replaceQueue(List<Song> songs, {shuffle = false}) async {
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

  List<Song> getQueuedSongs(BuildContext context) {
    if (_player.playlist == null) return [];

    SongProvider songProvider = context.read<SongProvider>();

    try {
      return _player.playlist!.audios
          .map((audio) => songProvider.byId(audio.metas.extra!['songId']))
          .toList();
    } catch (err) {
      print(err);
      return [];
    }
  }

  AssetsAudioPlayer get player => _player;

  void clearQueue() => _player.playlist!.audios.clear();
}

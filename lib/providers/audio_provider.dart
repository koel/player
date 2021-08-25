import 'dart:async';

import 'package:app/extensions/assets_audio_player.dart';
import 'package:app/extensions/audio.dart';
import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/interaction_provider.dart';
import 'package:app/providers/song_provider.dart';
import 'package:app/utils/preferences.dart' as preferences;
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';
import 'package:mutex/mutex.dart';

class AudioProvider with StreamSubscriber, ChangeNotifier {
  SongProvider _songProvider;
  InteractionProvider _interactionProvider;
  Mutex _mutex;

  late AssetsAudioPlayer _player;
  AssetsAudioPlayer get player => _player;

  AudioProvider({
    required SongProvider songProvider,
    required InteractionProvider interactionProvider,
  })  : _songProvider = songProvider,
        _interactionProvider = interactionProvider,
        _mutex = Mutex();

  Future<void> init() async {
    _player = AssetsAudioPlayer.newPlayer();

    subscribe(_player.current.listen((_) {
      // Everytime a new song is played (including those on Single loop mode)
      // we reset its playCountRegistered flag so that the play count is
      // registered properly.
      _songProvider.byId(_player.songId!).playCountRegistered = false;
    }));

    subscribe(_player.currentPosition.listen((Duration position) {
      if (player.songId == null) return;

      Song currentSong = _songProvider.byId(_player.songId!);

      if (currentSong.playCountRegistered) return;

      // If we've passed 25% of the song duration, register a play count
      if (position.inSeconds / currentSong.length.toDouble() > .25) {
        _interactionProvider.registerPlayCount(song: currentSong);
      }
    }));
  }

  Future<void> _openPlayer(audioResource) async {
    assert(audioResource is Audio || audioResource is List<Audio>,
        'audioResource must be of either Audio or List<Audio> type.');

    await _player.open(
      Playlist(
        audios: audioResource is Audio ? [audioResource] : audioResource,
      ),
      showNotification: true,
      autoStart: false,
      loopMode: preferences.loopMode,
      volume: preferences.volume,
    );

    notifyListeners();
  }

  Future<bool> queued(Song song) async => await indexInQueue(song) != -1;

  Future<int> indexInQueue(Song song) async {
    return _player.playlist?.audios.indexOf(await song.asAudio()) ?? -1;
  }

  Future<void> play({Song? song}) async {
    await _mutex.acquire();

    try {
      if (song == null) {
        return await _player.play();
      }

      int index = await indexInQueue(song);

      if (index != -1) {
        await _player.playlistPlayAtIndex(index);
      } else {
        await _player.playlistPlayAtIndex(
          _player.current.hasValue
              ? await queueAfterCurrent(song: song)
              : await queueToTop(song: song),
        );
      }

      await _player.play();
    } finally {
      _mutex.release();
    }
  }

  Future<void> stop() async => await _player.stop();

  Future<int> queueToTop({required Song song}) async {
    if (_player.playlist == null) {
      await _openPlayer(await song.asAudio());
      return 0;
    }

    _player.playlist!.insert(0, await song.asAudio());
    notifyListeners();
    return 0;
  }

  Future<int> queueToBottom({required Song song}) async {
    if (_player.playlist == null) {
      await _openPlayer(await song.asAudio());
    }

    _player.playlist!.add(await song.asAudio());
    notifyListeners();

    return _player.playlist!.numberOfItems - 1;
  }

  Future<int> queueAfterCurrent({required Song song}) async {
    if (_player.playlist == null) {
      await _openPlayer(await song.asAudio());
      return 0;
    }

    Audio audio = await song.asAudio();
    int currentSongIndex = _player.current.value?.index ?? -1;
    _player.playlist!.insert(currentSongIndex + 1, audio);
    notifyListeners();

    return currentSongIndex + 1;
  }

  Future<bool> playNext() async => await _player.next();

  Future<void> playOrPause() async => await _player.playOrPause();

  Future<void> replaceQueue(List<Song> songs, {shuffle = false}) async {
    List<Audio> audios = await Future.wait(
      songs.map((song) async => await song.asAudio()),
    );

    if (shuffle) {
      audios.shuffle();
    }

    _player.playlist?.audios.clear();
    await _player.stop();

    // Just reopen the player with the new audios
    await _openPlayer(audios);

    _player.play();
    notifyListeners();
  }

  List<Song> get queuedSongs {
    return _player.playlist?.audios
            .map((audio) => _songProvider.byId(audio.songId!))
            .toList() ??
        [];
  }

  void clearQueue() {
    _player.playlist?.audios.clear();
    notifyListeners();
  }

  Future<void> removeFromQueue({required Song song}) async {
    _player.playlist?.audios.remove(await song.asAudio());
    notifyListeners();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      // removing the item at oldIndex will shorten the list by 1.
      newIndex -= 1;
    }

    Audio? audio = _player.playlist?.audios[oldIndex];

    if (audio != null) {
      _player.playlist
        ?..remove(audio)
        ..insert(newIndex, audio);
      notifyListeners();
    }
  }

  ValueStream<PlayerState> get playerState => _player.playerState;

  Future<void> cleanUpUponLogout() async {
    await _player.stop();
    _player.playlist?.audios.clear();
  }
}

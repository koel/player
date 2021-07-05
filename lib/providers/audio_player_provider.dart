import 'dart:async';

import 'package:app/extensions/audio.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/interaction_provider.dart';
import 'package:app/providers/song_provider.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerProvider with ChangeNotifier {
  SongProvider _songProvider;
  InteractionProvider _interactionProvider;

  late final AssetsAudioPlayer _player;
  final BehaviorSubject<bool> _queueModified = BehaviorSubject();
  final List<StreamSubscription> _subscriptions = [];

  ValueStream<bool> get queueModifiedStream => _queueModified.stream;
  Audio? _currentAudio;
  Song? _currentSong;

  AudioPlayerProvider({
    required SongProvider songProvider,
    required InteractionProvider interactionProvider,
  })  : _songProvider = songProvider,
        _interactionProvider = interactionProvider;

  // Set a blank audio to ensure the playlist is initialized
  // (Assets Audio Player will set playlist to NULL if the list is empty).
  final Audio seededAudio = Audio('assets/audio/blank.mp3');

  Future<void> init() async {
    _player = AssetsAudioPlayer.newPlayer();

    _subscriptions
      ..add(_player.current.listen((Playing? playing) {
        if (playing?.audio.audio != seededAudio) {
          _currentAudio = playing!.audio.audio;
          _currentSong = _songProvider.byId(_currentAudio!.songId!);
          _currentSong!.playCountRegistered = false;
        }
      }))
      ..add(_player.currentPosition.listen((Duration position) {
        if (_currentSong == null) return;

        // If we've passed 25% of the song duration, register a play count
        if (position.inSeconds / _currentSong!.length.toDouble() > .25) {
          _interactionProvider.registerPlayCount(song: _currentSong!);
        }
      }));

    await _player.open(
      Playlist(audios: [seededAudio]),
      showNotification: true,
      autoStart: false,
    );

    try {
      _player.playlist?.removeAtIndex(0);
    } catch (err) {
      // AssetAudioPlayer throws a "Unhandled Exception: RangeError (index): Invalid value: Valid value range is empty: 0"
      // error here.
    }
    _broadcastQueueChangedEvent();
  }

  Future<bool> queued(Song song) async => await indexInQueue(song) != -1;

  Future<int> indexInQueue(Song song) async {
    return _player.playlist?.audios.indexOf(await song.asAudio()) ?? -1;
  }

  Future<int> queueAfterCurrent(Song song) async {
    Audio audio = await song.asAudio();
    int index = _player.playlist?.audios.indexOf(_currentAudio!) ?? 0 + 1;
    _player.playlist?.insert(index, audio);
    _broadcastQueueChangedEvent();

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
    _player.playlist?.insert(0, await song.asAudio());
    _broadcastQueueChangedEvent();
    return 0;
  }

  Future<int> queueToBottom(Song song) async {
    _player.playlist?.add(await song.asAudio());
    _broadcastQueueChangedEvent();
    return _player.playlist?.numberOfItems ?? -1;
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
    _broadcastQueueChangedEvent();
  }

  List<Song> get queuedSongs {
    if (_player.playlist == null) return [];

    return _player.playlist?.audios
            .where((element) => element.path != 'assets/audio/blank.mp3')
            .map((audio) => _songProvider.byId(audio.metas.extra!['songId']))
            .toList() ??
        [];
  }

  AssetsAudioPlayer get player => _player;

  void clearQueue() {
    _player.playlist?.audios.clear();
    _broadcastQueueChangedEvent();
  }

  Future<void> removeFromQueue(Song song) async {
    _player.playlist?.audios.remove(await song.asAudio());
    _broadcastQueueChangedEvent();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      // removing the item at oldIndex will shorten the list by 1.
      newIndex -= 1;
    }

    Audio? audio = _player.playlist?.audios[oldIndex];

    if (audio != null) {
      _player.playlist?.remove(audio);
      _player.playlist?.insert(newIndex, audio);
      _broadcastQueueChangedEvent();
    }
  }

  void _broadcastQueueChangedEvent() => _queueModified.add(true);

  @override
  Future<void> dispose() async {
    await _queueModified.close();
    super.dispose();
  }
}

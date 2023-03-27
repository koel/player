import 'package:app/main.dart';
import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/utils/api_request.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';

class InteractionProvider with ChangeNotifier, StreamSubscriber {
  late SongProvider _songProvider;

  InteractionProvider({required SongProvider songProvider}) {
    _songProvider = songProvider;
    subscribeToAudioEvents();
  }

  subscribeToAudioEvents() {
    subscribe(audioHandler.playbackState.listen((state) {
      if (audioHandler.mediaItem.value == null) return;
      // every time the song completes, reset the play count registered flag
      // so that next time the song is played, the count will be registered again.
      if (state.processingState == AudioProcessingState.completed) {
        Song? song = _songProvider.byId(audioHandler.mediaItem.value!.id);
        if (song != null) song.playCountRegistered = false;
      }
    }));

    subscribe(audioHandler.player.positionStream.listen((duration) {
      if (audioHandler.mediaItem.value == null) return;
      Song? song = _songProvider.byId(audioHandler.mediaItem.value!.id);
      if (song != null &&
          !song.playCountRegistered &&
          duration.inSeconds / song.length.toDouble() > .25) {
        song.playCountRegistered = true;
        registerPlayCount(song: song);
      }
    }));
  }

  List<Song> get favorites =>
      _songProvider.songs.where((song) => song.liked).toList();

  Future<void> _like({required Song song}) async {
    song.liked = true;
    notifyListeners();
    await post('interaction/like', data: {'song': song.id});
  }

  Future<void> _unlike({required Song song}) async {
    song.liked = false;
    notifyListeners();
    await post('interaction/like', data: {'song': song.id});
  }

  Future<void> toggleLike({required Song song}) async {
    return song.liked ? _unlike(song: song) : _like(song: song);
  }

  Future<void> registerPlayCount({required Song song}) async {
    song.playCountRegistered = true;
    dynamic json = await post('interaction/play', data: {'song': song.id});

    // Use the data from the server to make sure we don't miss a play from another device.
    Interaction interaction = Interaction.fromJson(json);
    song
      ..playCount = interaction.playCount
      ..liked = interaction.liked;
  }

  @override
  dispose() {
    super.dispose();
    unsubscribeAll();
  }
}

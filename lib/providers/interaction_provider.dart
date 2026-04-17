import 'package:app/main.dart';
import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/utils/api_request.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';

class InteractionProvider with ChangeNotifier, StreamSubscriber {
  late final PlayableProvider _playableProvider;
  late final RecentlyPlayedProvider _recentlyPlayedProvider;
  late final DownloadProvider _downloadProvider;

  InteractionProvider({
    required PlayableProvider playableProvider,
    required RecentlyPlayedProvider recentlyPlayedProvider,
    required DownloadProvider downloadProvider,
  })  : _playableProvider = playableProvider,
        _recentlyPlayedProvider = recentlyPlayedProvider,
        _downloadProvider = downloadProvider {
    _subscribeToAudioEvents();
  }

  _subscribeToAudioEvents() {
    subscribe(audioHandler.playbackState.listen((state) {
      if (audioHandler.mediaItem.value == null) return;
      // every time the song completes, reset the play count registered flag
      // so that next time the song is played, the count will be registered again.
      if (state.processingState == AudioProcessingState.completed) {
        final playable = _playableProvider.byId(
          audioHandler.mediaItem.value!.id,
        );

        if (playable == null) return; // should never happen

        playable.playCountRegistered = false;
      }
    }));

    subscribe(audioHandler.player.positionStream.listen((duration) {
      if (audioHandler.mediaItem.value == null) return;
      final song = _playableProvider.byId(audioHandler.mediaItem.value!.id);

      if (song != null &&
          !song.playCountRegistered &&
          duration.inSeconds / song.length > .25) {
        song.playCountRegistered = true;
        _recentlyPlayedProvider.add(song);
        _registerPlayCount(playable: song);
      }
    }));
  }

  Future<void> _like({required Song song}) async {
    song.liked = true;
    notifyListeners();
    try {
      await post('interaction/like', data: {'song': song.id});
      _downloadProvider.persistMetadataIfNeeded(song);
    } catch (e) {
      song.liked = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _unlike({required Song song}) async {
    song.liked = false;
    notifyListeners();
    try {
      await post('interaction/like', data: {'song': song.id});
      _downloadProvider.persistMetadataIfNeeded(song);
    } catch (e) {
      song.liked = true;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleLike({required Song song}) async {
    return song.liked ? _unlike(song: song) : _like(song: song);
  }

  Future<void> _registerPlayCount({required Playable playable}) async {
    playable.playCountRegistered = true;
    final json = await post('interaction/play', data: {'song': playable.id});

    // Use the data from the server to make sure we don't miss a play from another device.
    final interaction = Interaction.fromJson(json);
    playable
      ..playCount = interaction.playCount
      ..liked = interaction.liked;
    if (playable is Song) _downloadProvider.persistMetadataIfNeeded(playable);
  }

  @override
  dispose() {
    super.dispose();
    unsubscribeAll();
  }
}

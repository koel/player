import 'package:app/models/interaction.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/song_provider.dart';
import 'package:app/utils/api_request.dart';
import 'package:flutter/foundation.dart';

class InteractionProvider with ChangeNotifier {
  SongProvider _songProvider;

  InteractionProvider({required SongProvider songProvider})
      : _songProvider = songProvider;

  List<Song> get favorites =>
      _songProvider.songs.where((song) => song.liked).toList();

  Future<void> like({required Song song}) async {
    // Broadcast the event first regardless
    song.liked = true;
    notifyListeners();
    await post('interaction/like', data: {'song': song.id});
  }

  Future<void> unlike({required Song song}) async {
    // Broadcast the event first regardless
    song.liked = false;
    notifyListeners();
    await post('interaction/like', data: {'song': song.id});
  }

  Future<void> toggleLike({required Song song}) async {
    return song.liked ? unlike(song: song) : like(song: song);
  }

  List<Song> getRandomFavorites({int limit = 15}) {
    List<Song> clone = List.from(favorites);
    clone.shuffle();
    return clone.take(limit).toList();
  }

  Future<void> registerPlayCount({required Song song}) async {
    // Prevent continuous calls to this function
    song.playCountRegistered = true;
    dynamic json = await post('interaction/play', data: {'song': song.id});

    // Use the data from the server to make sure we don't miss a play from another device.
    Interaction interaction = Interaction.fromJson(json);
    int oldCount = song.playCount;
    song
      ..playCount = interaction.playCount
      ..album.playCount += song.playCount - oldCount
      ..artist.playCount += song.playCount - oldCount
      // might as well
      ..liked = interaction.liked;
  }
}

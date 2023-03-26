import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/utils/api_request.dart';
import 'package:flutter/foundation.dart';

class InteractionProvider with ChangeNotifier {
  SongProvider _songProvider;

  InteractionProvider({required SongProvider songProvider})
      : _songProvider = songProvider;

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
}

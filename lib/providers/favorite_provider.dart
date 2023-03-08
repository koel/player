import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/utils/api_request.dart';
import 'package:flutter/foundation.dart';

class FavoriteProvider with ChangeNotifier {
  List<Song> songs = [];
  SongProvider songProvider;

  FavoriteProvider({required this.songProvider});

  Future<List<Song>> fetch() async {
    // @todo: cache this request
    var response = await get('songs/favorite');
    List<Song> _songs = response.map<Song>((j) => Song.fromJson(j)).toList();
    songs = songProvider.syncWithVault(_songs);

    notifyListeners();

    return songs;
  }

  Future<void> unlike({required Song song}) async {
    song.liked = false;
    songs.remove(song);
    notifyListeners();

    await post('interaction/like', data: {'song': song.id});
  }
}

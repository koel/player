import 'package:app/models/playlist.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/song_provider.dart';
import 'package:app/utils/api_request.dart';
import 'package:app/values/parse_result.dart';
import 'package:flutter/foundation.dart';

ParseResult parsePlaylists(List<dynamic> data) {
  ParseResult result = ParseResult();
  data.forEach((json) => result.add(Playlist.fromJson(json), json['id']));

  return result;
}

class PlaylistProvider with ChangeNotifier {
  SongProvider _songProvider;
  late List<Playlist> _playlists;

  PlaylistProvider({required SongProvider songProvider})
      : _songProvider = songProvider;

  Future<void> init(List<dynamic> playlistData) async {
    ParseResult result = await compute(parsePlaylists, playlistData);
    _playlists = result.collection.cast();
  }

  List<Playlist> get playlists => _playlists;

  Future<Playlist> populatePlaylist({required Playlist playlist}) async {
    if (!playlist.populated) {
      List<dynamic> response = await get('playlist/${playlist.id}/songs');

      response.cast<String>().forEach((id) {
        Song? song = _songProvider.tryById(id);
        if (song != null) {
          playlist.songs.add(song);
        }
      });

      playlist.populated = true;
    }

    return playlist;
  }
}

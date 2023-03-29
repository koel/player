import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/utils/api_request.dart';
import 'package:app/values/values.dart';
import 'package:flutter/foundation.dart';

ParseResult parsePlaylists(List<dynamic> data) {
  ParseResult result = ParseResult();
  data.forEach((json) => result.add(Playlist.fromJson(json), json['id']));

  return result;
}

class PlaylistProvider with ChangeNotifier {
  AppStateProvider _appState;
  var _playlists = <Playlist>[];

  PlaylistProvider({required AppStateProvider appState}) : _appState = appState;

  Future<void> init(List<dynamic> playlistData) async {
    ParseResult result = await compute(parsePlaylists, playlistData);
    _playlists = result.collection.cast();
    notifyListeners();
  }

  List<Playlist> get playlists => _playlists;

  List<Playlist> get standardPlaylists =>
      _playlists.where((playlist) => playlist.isStandard).toList();

  Future<void> addSongToPlaylist(
    Song song, {
    required Playlist playlist,
  }) async {
    assert(!playlist.isSmart, 'Cannot manually mutate smart playlists.');

    await post('playlists/${playlist.id}/songs', data: {
      'songs': [song.id],
    });

    final cachedSongs =
        _appState.get<List<Song>>(['playlist.songs', playlist.id]);

    if (cachedSongs != null && !cachedSongs.contains(song)) {
      // add the song into the playlist's songs cache
      _appState.set(['playlist.songs', playlist.id], cachedSongs..add(song));
    }
  }

  Future<void> removeSongFromPlaylist(
    Song song, {
    required Playlist playlist,
  }) async {
    assert(!playlist.isSmart, 'Cannot manually mutate smart playlists.');

    await delete('playlists/${playlist.id}/songs', data: {
      'songs': [song.id],
    });

    final cachedSongs =
        _appState.get<List<Song>>(['playlist.songs', playlist.id]);

    if (cachedSongs != null && cachedSongs.contains(song)) {
      // remove the song from the playlist's songs cache
      _appState.set(['playlist.songs', playlist.id], cachedSongs..remove(song));
    }
  }

  Future<Playlist> create({required String name}) async {
    final json = await post('playlist', data: {
      'name': name,
    });

    Playlist playlist = Playlist.fromJson(json);
    _playlists.add(playlist);
    notifyListeners();

    return playlist;
  }

  Future<void> remove(Playlist playlist) async {
    // For a snappier experience, we don't `await` the operation.
    delete('playlists/${playlist.id}');
    _playlists.remove(playlist);

    notifyListeners();
  }
}

import 'package:app/app_state.dart';
import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/auth_provider.dart';
import 'package:app/utils/api_request.dart';
import 'package:flutter/foundation.dart';

class PlaylistProvider with ChangeNotifier, StreamSubscriber {
  var _playlists = <Playlist>[];

  PlaylistProvider() {
    subscribe(AuthProvider.userLoggedOutStream.listen((_) {
      _playlists.clear();
      notifyListeners();
    }));
  }

  Future<void> init(List<dynamic> playlistData) async {
    _playlists = _parsePlaylistsFromJson(playlistData);
    notifyListeners();
  }

  List<Playlist> get playlists => _playlists;

  List<Playlist> get standardPlaylists =>
      _playlists.where((playlist) => playlist.isStandard).toList();

  Future<void> addToPlaylist(
    Playable playable, {
    required Playlist playlist,
  }) async {
    assert(!playlist.isSmart, 'Cannot manually mutate smart playlists.');

    await post('playlists/${playlist.id}/songs', data: {
      'songs': [playable.id],
    });

    final cachedPlayables =
        AppState.get<List<Playable>>(['playlist.playables', playlist.id]);

    if (cachedPlayables != null && !cachedPlayables.contains(playable)) {
      // add the song into the playlist's songs cache
      AppState.set(
        ['playlist.playables', playlist.id],
        cachedPlayables..add(playable),
      );
    }
  }

  Future<void> removeFromPlaylist(
    Playable playable, {
    required Playlist playlist,
  }) async {
    assert(!playlist.isSmart, 'Cannot manually mutate smart playlists.');

    await delete('playlists/${playlist.id}/songs', data: {
      'songs': [playable.id],
    });

    final cachedPlayables =
        AppState.get<List<Playable>>(['playlist.playables', playlist.id]);

    if (cachedPlayables != null && cachedPlayables.contains(playable)) {
      // remove the song from the playlist's songs cache
      AppState.set(
        ['playlist.playables', playlist.id],
        cachedPlayables..remove(playable),
      );
    }
  }

  Future<Playlist> create({required String name}) async {
    final json = await post('playlists', data: {
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

  Future<void> fetchAll() async {
    _playlists = _parsePlaylistsFromJson(await get('playlists'));
    notifyListeners();
  }

  List<Playlist> _parsePlaylistsFromJson(List<dynamic> json) {
    return json.map<Playlist>((j) => Playlist.fromJson(j)).toList();
  }
}

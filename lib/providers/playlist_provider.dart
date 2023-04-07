import 'package:app/models/playlist.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/song_provider.dart';
import 'package:app/utils/api_request.dart';
import 'package:app/values/parse_result.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

ParseResult parsePlaylists(List<dynamic> data) {
  ParseResult result = ParseResult();
  data.forEach((json) => result.add(Playlist.fromJson(json), json['id']));

  return result;
}

class PlaylistProvider with ChangeNotifier {
  SongProvider _songProvider;
  late List<Playlist> _playlists;

  final BehaviorSubject<Playlist> _playlistPopulated = BehaviorSubject();

  ValueStream<Playlist> get playlistPopulatedStream =>
      _playlistPopulated.stream;

  PlaylistProvider({required SongProvider songProvider})
      : _songProvider = songProvider;

  Future<void> init(List<dynamic> playlistData) async {
    ParseResult result = await compute(parsePlaylists, playlistData);
    _playlists = result.collection.cast();
    notifyListeners();
  }

  List<Playlist> get playlists => _playlists;

  List<Playlist> get standardPlaylists =>
      _playlists.where((playlist) => playlist.isStandard).toList();

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
      _playlistPopulated.add(playlist);
    }

    return playlist;
  }

  void populateAllPlaylists() {
    _playlists.forEach((playlist) => populatePlaylist(playlist: playlist));
  }

  Future<void> addSongToPlaylist({
    required Song song,
    required Playlist playlist,
  }) async {
    assert(!playlist.isSmart, 'Cannot manually mutate smart playlists.');

    if (!playlist.populated) {
      await populatePlaylist(playlist: playlist);
    }

    if (playlist.songs.contains(song)) return;

    try {
      await _syncPlaylist(playlist: playlist..songs.add(song));
    } catch (err) {
      print(err);
      // not the end of the world
    }
  }

  Future<void> removeSongFromPlaylist({
    required Song song,
    required Playlist playlist,
  }) async {
    assert(!playlist.isSmart, 'Cannot manually mutate smart playlists.');

    if (!playlist.songs.contains(song)) return;

    try {
      await _syncPlaylist(playlist: playlist..songs.remove(song));
    } catch (err) {
      print(err);
      // not the end of the world
    }
  }

  Future<Playlist> create({required String name}) async {
    var json = await post('playlist', data: {
      'name': name,
    });

    Playlist playlist = Playlist.fromJson(json);
    _playlists.add(playlist);
    notifyListeners();

    return playlist;
  }

  Future<void> _syncPlaylist({required Playlist playlist}) async {
    await put('playlist/${playlist.id}/sync', data: {
      'songs': playlist.songs.map((song) => song.id).toList(),
    });

    _playlistPopulated.add(playlist);
  }

  Future<void> remove({required Playlist playlist}) async {
    // For a snappier experience, we don't `await` the operation.
    delete('playlist/${playlist.id}');
    _playlists.remove(playlist);
  }
}

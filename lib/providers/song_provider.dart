import 'package:app/enums.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/widgets/app_bar.dart';
import 'package:app/utils/api_request.dart';
import 'package:app/values/values.dart';
import 'package:flutter/foundation.dart';

class SongProvider with ChangeNotifier {
  late ArtistProvider artistProvider;
  late AlbumProvider albumProvider;
  late CacheProvider cacheProvider;
  late CoverImageStack coverImageStack;

  List<Song> songs = [];
  Map<String, Song> vault = {};

  SongProvider({
    required this.artistProvider,
    required this.albumProvider,
    required this.cacheProvider,
  });

  List<Song> syncWithVault(dynamic _songs) {
    if (!(_songs is List<Song> || _songs is Song)) {
      throw Exception('Invalid type for songs. Must be List<Song> or Song.');
    }

    if (_songs is Song) {
      _songs = [_songs];
    }

    List<Song> synced = (_songs as List<Song>).map<Song>((remote) {
      Song? local = byId(remote.id);

      if (local == null) {
        vault[remote.id] = remote;
        return remote;
      } else {
        return local.merge(remote);
      }
    }).toList();

    return synced;
  }

  List<Song> recentlyAdded({int limit = 5}) {
    List<Song> clone = List<Song>.from(songs);
    clone.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return clone.take(limit).toList();
  }

  List<Song> mostPlayed({int limit = 15}) {
    List<Song> clone = List<Song>.from(songs);
    clone.sort((a, b) => b.playCount.compareTo(a.playCount));
    return clone.take(limit).toList();
  }

  List<Song> leastPlayed({int limit = 15}) {
    List<Song> clone = List<Song>.from(songs);
    clone.sort((a, b) => a.playCount.compareTo(b.playCount));
    return clone.take(limit).toList();
  }

  Song? byId(String id) => vault[id];

  List<Song> byIds(List<String> ids) {
    List<Song> songs = [];

    ids.forEach((id) {
      if (vault.containsKey(id)) {
        songs.add(vault[id]!);
      }
    });

    return songs;
  }

  List<Song> byArtist(Artist artist) =>
      songs.where((song) => song.artistId == artist.id).toList();

  List<Song> byAlbum(Album album) =>
      songs.where((song) => song.albumId == album.id).toList();

  List<Song> favorites() => songs.where((song) => song.liked).toList();

  Future<List<Song>> fetchForAlbum(int albumId) async {
    // @todo - cache this
    var response = await get('albums/$albumId/songs');
    List<Song> songs =
        response.data.map((json) => Song.fromJson(json)).toList();

    return syncWithVault(songs);
  }

  Future<PaginationResult<Song>> paginate(
    String sortField,
    SortOrder sortOrder,
    int page,
  ) async {
    // @todo - cache this
    var response = await get(
      'songs?page=$page&sort=$sortField&order=${sortOrder.value}',
    );
    List<Song> _songs =
        response['data'].map<Song>((json) => Song.fromJson(json)).toList();
    List<Song> synced = syncWithVault(_songs);

    songs = [...songs, ...synced].toSet().toList();
    notifyListeners();

    return new PaginationResult(
      items: synced,
      nextPage:
          response['links']['next'] ? ++response['meta']['current_page'] : null,
    );
  }
}

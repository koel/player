import 'package:app/models/album.dart';
import 'package:app/models/artist.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/album_provider.dart';
import 'package:app/providers/artist_provider.dart';
import 'package:app/values/parse_result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

ParseResult parseSongs(List<dynamic> data) {
  ParseResult result = ParseResult();
  data.forEach((json) => result.add(Song.fromJson(json), json['id']));

  return result;
}

class SongProvider with ChangeNotifier {
  ArtistProvider _artistProvider;
  AlbumProvider _albumProvider;

  late List<Song> _songs;
  late Map<String, Song> _index;

  SongProvider({
    required ArtistProvider artistProvider,
    required AlbumProvider albumProvider,
  })  : _artistProvider = artistProvider,
        _albumProvider = albumProvider;

  Future<void> init(List<dynamic> songData) async {
    ParseResult result = await compute(parseSongs, songData);
    _songs = result.collection.cast();
    _index = result.index.cast();

    _songs.forEach((song) {
      song.artist = _artistProvider.byId(song.artistId);
      song.album = _albumProvider.byId(song.albumId);
    });
  }

  void initInteractions(List<dynamic> interactionData) {
    interactionData.forEach((element) {
      Song _song = byId(element['song_id']);
      _song.liked = element['liked'];
      _song.playCount = element['play_count'];
      _song.artist.playCount += _song.playCount;
      _song.album.playCount += _song.playCount;
    });
  }

  List<Song> recentlyAdded({int limit = 5}) {
    List<Song> clone = List<Song>.from(_songs);
    clone.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return clone.take(limit).toList();
  }

  List<Song> mostPlayed({int limit = 15}) {
    List<Song> clone = List<Song>.from(_songs);
    clone.sort((a, b) => b.playCount.compareTo(a.playCount));
    return clone.take(limit).toList();
  }

  List<Song> leastPlayed({int limit = 15}) {
    List<Song> clone = List<Song>.from(_songs);
    clone.sort((a, b) => a.playCount.compareTo(b.playCount));
    return clone.take(limit).toList();
  }

  Song byId(String id) => _index[id]!;

  Song? tryById(String id) => _index[id];

  List<Song> byIds(List<String> ids) {
    List<Song> songs = [];

    ids.forEach((id) {
      if (_index.containsKey(id)) {
        songs.add(_index[id]!);
      }
    });

    return songs;
  }

  List<Song> byArtist(Artist artist) =>
      _songs.where((song) => song.artist == artist).toList();

  List<Song> byAlbum(Album album) =>
      _songs.where((song) => song.album == album).toList();

  List<Song> favorites() => _songs.where((song) => song.liked).toList();

  List<Song> get songs => _songs;
}

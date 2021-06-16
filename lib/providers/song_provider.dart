import 'package:app/models/artist.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/album_provider.dart';
import 'package:app/providers/artist_provider.dart';
import 'package:app/providers/requires_initialization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class SongProvider with ChangeNotifier, RequiresInitialization {
  List<Song> _songs = <Song>[];

  void init(BuildContext context, List<dynamic> songData) {
    AlbumProvider albumProvider =
        Provider.of<AlbumProvider>(context, listen: false);
    ArtistProvider artistProvider =
        Provider.of<ArtistProvider>(context, listen: false);

    albumProvider.ensureInitialization();
    artistProvider.ensureInitialization();

    songData.forEach((element) {
      _songs.add(Song.fromJson(
        element,
        albumProvider.byId(element['album_id']),
        artistProvider.byId(element['artist_id']),
      ));
    });

    initialized = true;
  }

  void initInteractions(BuildContext context, List<dynamic> interactionData) {
    interactionData.forEach((element) {
      Song _song = byId(element['song_id']);
      _song.liked = element['liked'];
      _song.playCount = element['play_count'];
      _song.artist.playCount += _song.playCount;
      _song.album.playCount += _song.playCount;
    });
  }

  List<Song> recentlyAdded({int limit = 6}) {
    List<Song> clone = List<Song>.from(_songs);
    clone.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return clone.sublist(0, limit);
  }

  List<Song> mostPlayed({int limit = 15}) {
    List<Song> clone = List<Song>.from(_songs);
    clone.sort((a, b) => b.playCount.compareTo(a.playCount));
    return clone.sublist(0, limit);
  }

  Song byId(String id) {
    return _songs.firstWhere((song) => song.id == id);
  }

  List<Song> byArtist(Artist artist) {
    return _songs.where((song) => song.artist == artist).toList();
  }
}

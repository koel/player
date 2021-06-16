import 'package:app/models/artist.dart';
import 'package:app/providers/requires_initialization.dart';
import 'package:flutter/cupertino.dart';

class ArtistProvider with ChangeNotifier, RequiresInitialization {
  List<Artist> _artists = <Artist>[];

  List<Artist> get artists => _artists;

  void init(BuildContext context, List<dynamic> artistData) {
    artistData.forEach((element) => _artists.add(Artist.fromJson(element)));
    initialized = true;
  }

  Artist byId(int id) {
    return _artists.firstWhere((song) => song.id == id);
  }

  List<Artist> mostPlayed({int limit = 15}) {
    List<Artist> clone = List<Artist>.from(_artists);
    clone.sort((a, b) => b.playCount.compareTo(a.playCount));
    return clone.sublist(0, limit);
  }
}

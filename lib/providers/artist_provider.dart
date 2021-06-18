import 'package:app/models/artist.dart';
import 'package:app/values/parse_result.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

ParseResult parseArtists(List<dynamic> data) {
  ParseResult result = ParseResult();

  data.forEach((element) {
    result.add(Artist.fromJson(element), element['id']);
  });

  return result;
}

class ArtistProvider with ChangeNotifier {
  late List<Artist> _artists;
  late Map<int, Artist> _index;

  List<Artist> get artists => _artists;

  Future<void> init(BuildContext context, List<dynamic> artistData) async {
    ParseResult result = await compute(parseArtists, artistData);
    _artists = result.collection.cast();
    _index = result.index.cast();
  }

  Artist byId(int id) {
    return _index[id]!;
  }

  List<Artist> mostPlayed({int limit = 15}) {
    List<Artist> clone = List<Artist>.from(_artists);
    clone.sort((a, b) => b.playCount.compareTo(a.playCount));
    return clone.sublist(0, limit);
  }
}

import 'package:app/models/album.dart';
import 'package:app/values/parse_result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'artist_provider.dart';

ParseResult parseAlbums(List<dynamic> data) {
  ParseResult result = ParseResult();

  data.forEach((element) {
    result.add(Album.fromJson(element), element['id']);
  });

  return result;
}

class AlbumProvider with ChangeNotifier {
  late List<Album> _albums;
  late Map<int, Album> _index;

  List<Album> get albums => _albums;

  Future<void> init(BuildContext context, List<dynamic> albumData) async {
    ArtistProvider artistProvider =
        Provider.of<ArtistProvider>(context, listen: false);

    ParseResult result = await compute(parseAlbums, albumData);
    _albums = result.collection.cast();
    _index = result.index.cast();

    _albums.forEach((album) {
      album.artist = artistProvider.byId(album.artistId);
    });
  }

  Album byId(int id) {
    return _index[id]!;
  }

  List<Album> mostPlayed({int limit = 15}) {
    List<Album> clone = List<Album>.from(_albums)
        .where((album) => album.isStandardAlbum)
        .toList();
    clone.sort((a, b) => b.playCount.compareTo(a.playCount));
    return clone.sublist(0, limit);
  }
}

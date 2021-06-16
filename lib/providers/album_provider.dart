import 'package:app/models/album.dart';
import 'package:app/providers/requires_initialization.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'artist_provider.dart';

class AlbumProvider with ChangeNotifier, RequiresInitialization {
  List<Album> _albums = <Album>[];

  List<Album> get albums => _albums;

  void init(BuildContext context, List<dynamic> albumData) {
    ArtistProvider artistProvider =
        Provider.of<ArtistProvider>(context, listen: false);

    if (!artistProvider.initialized) {
      throw Exception('ArtistProvider must be initialized first');
    }

    albumData.forEach((element) {
      _albums.add(Album.fromJson(
        element,
        artistProvider.byId(element['artist_id']),
      ));
    });

    initialized = true;
  }

  Album byId(int id) {
    return _albums.firstWhere((album) => album.id == id);
  }

  List<Album> topAlbums() {
    return [];
  }
}

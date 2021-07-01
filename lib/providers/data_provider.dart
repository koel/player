import 'package:app/providers/album_provider.dart';
import 'package:app/providers/artist_provider.dart';
import 'package:app/providers/song_provider.dart';
import 'package:app/utils/api_request.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class DataProvider with ChangeNotifier {
  SongProvider _songProvider;
  AlbumProvider _albumProvider;
  ArtistProvider _artistProvider;

  DataProvider({
    required SongProvider songProvider,
    required AlbumProvider albumProvider,
    required ArtistProvider artistProvider,
  })  : _songProvider = songProvider,
        _albumProvider = albumProvider,
        _artistProvider = artistProvider;

  Future<void> init(BuildContext context) async {
    final Map<String, dynamic> data = await get('data');

    await _artistProvider.init(data['artists']);
    await _albumProvider.init(data['albums']);

    await _songProvider.init(data['songs']);
    _songProvider.initInteractions(data['interactions']);
  }
}

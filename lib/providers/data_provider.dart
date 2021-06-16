import 'package:app/providers/album_provider.dart';
import 'package:app/providers/artist_provider.dart';
import 'package:app/providers/song_provider.dart';
import 'package:app/utils/api_request.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class DataProvider with ChangeNotifier {
  Future<void> init(BuildContext context) async {
    final Map<String, dynamic> data = await ApiRequest.get('data');

    Provider.of<ArtistProvider>(context, listen: false)
        .init(context, data['artists']);
    Provider.of<AlbumProvider>(context, listen: false)
        .init(context, data['albums']);
    Provider.of<SongProvider>(context, listen: false)
        ..init(context, data['songs'])
        ..initInteractions(context, data['interactions']);
  }
}

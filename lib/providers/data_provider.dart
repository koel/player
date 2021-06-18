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

    await Provider.of<ArtistProvider>(context, listen: false)
        .init(context, data['artists']);
    await Provider.of<AlbumProvider>(context, listen: false)
        .init(context, data['albums']);

    SongProvider songProvider =
        Provider.of<SongProvider>(context, listen: false);
    await songProvider.init(context, data['songs']);
    songProvider.initInteractions(context, data['interactions']);
  }
}

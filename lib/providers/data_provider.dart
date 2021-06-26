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

    await context.read<ArtistProvider>().init(data['artists']);
    await context.read<AlbumProvider>().init(context, data['albums']);

    SongProvider songProvider = context.read<SongProvider>();
    await songProvider.init(context, data['songs']);
    songProvider.initInteractions(context, data['interactions']);
  }
}

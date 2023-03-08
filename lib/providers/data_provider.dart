import 'package:app/providers/providers.dart';
import 'package:app/utils/api_request.dart';
import 'package:flutter/widgets.dart';

class DataProvider with ChangeNotifier {
  PlaylistProvider playlistProvider;

  DataProvider({required this.playlistProvider});

  Future<void> init(BuildContext context) async {
    final Map<String, dynamic> data = await get('data');

    await playlistProvider.init(data['playlists']);
  }
}

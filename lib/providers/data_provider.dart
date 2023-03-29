import 'package:app/main.dart';
import 'package:app/providers/providers.dart';
import 'package:app/utils/api_request.dart';
import 'package:flutter/widgets.dart';

class DataProvider with ChangeNotifier {
  final PlaylistProvider playlistProvider;

  DataProvider({required this.playlistProvider});

  Future<void> init() async {
    final Map<String, dynamic> data = await get('data');

    appState.set(['app', 'useLastFm'], data['use_last_fm']);
    appState.set(['app', 'songCount'], data['song_count']);
    appState.set(['app', 'cdnUrl'], data['cdn_url']);
    appState.set(['app', 'transcoding'], data['transcoding']);

    await playlistProvider.init(data['playlists']);
  }
}

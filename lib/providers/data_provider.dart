import 'package:app/app_state.dart';
import 'package:app/providers/providers.dart';
import 'package:app/utils/api_request.dart';
import 'package:flutter/widgets.dart';

class DataProvider with ChangeNotifier {
  final PlaylistProvider _playlistProvider;

  DataProvider({required playlistProvider})
      : _playlistProvider = playlistProvider;

  Future<void> init() async {
    final Map<String, dynamic> data = await get('data');

    AppState.set(['app', 'useLastFm'], data['use_last_fm']);
    AppState.set(['app', 'songCount'], data['song_count']);
    AppState.set(['app', 'cdnUrl'], data['cdn_url']);
    AppState.set(['app', 'transcoding'], data['transcoding']);

    await _playlistProvider.init(data['playlists']);
  }
}

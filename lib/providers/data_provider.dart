import 'package:app/app_state.dart';
import 'package:app/providers/providers.dart';
import 'package:app/utils/api_request.dart';
import 'package:app/values/values.dart';
import 'package:flutter/widgets.dart';
import 'package:version/version.dart';

class DataProvider with ChangeNotifier {
  final PlaylistProvider _playlistProvider;
  final SongProvider _songProvider;

  DataProvider({required playlistProvider, required songProvider})
      : _playlistProvider = playlistProvider,
        _songProvider = songProvider;

  Future<void> init() async {
    final Map<String, dynamic> data = await get('data');

    AppState.set(['app', 'useLastFm'], data['use_last_fm']);
    AppState.set(['app', 'songCount'], data['song_count']);
    AppState.set(['app', 'cdnUrl'], data['cdn_url']);
    AppState.set(['app', 'transcoding'], data['transcoding']);

    // Since the API version starts with v, we need to remove it before parsing
    AppState.set(
      ['app', 'apiVersion'],
      Version.parse(data['current_version'].toString().substring(1)),
    );

    if (data.containsKey('queue_state')) {
      AppState.set(
        ['app', 'queueState'],
        QueueState.parse(data['queue_state'], _songProvider),
      );
    } else {
      AppState.set(['app', 'queueState'], QueueState.empty());
    }

    await _playlistProvider.init(data['playlists']);
  }
}

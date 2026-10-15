import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/auth_provider.dart';
import 'package:app/utils/api_request.dart';
import 'package:flutter/foundation.dart';

class PlaylistFolderProvider with ChangeNotifier, StreamSubscriber {
  var _folders = <PlaylistFolder>[];

  List<PlaylistFolder> get folders => _folders;

  PlaylistFolderProvider() {
    subscribe(AuthProvider.userLoggedOutStream.listen((_) {
      _folders.clear();
      notifyListeners();
    }));
  }

  void init(List<dynamic> folderData) {
    _folders = folderData
        .map<PlaylistFolder>((j) => PlaylistFolder.fromJson(j))
        .toList();
    notifyListeners();
  }

  PlaylistFolder? byId(String id) {
    try {
      return _folders.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<PlaylistFolder> create({required String name}) async {
    final json = await post('playlist-folders', data: {'name': name});
    final folder = PlaylistFolder.fromJson(json);
    _folders.add(folder);
    notifyListeners();
    return folder;
  }

  Future<void> rename(PlaylistFolder folder, {required String name}) async {
    await patch('playlist-folders/${folder.id}', data: {'name': name});
    folder.name = name;
    notifyListeners();
  }

  Future<void> remove(PlaylistFolder folder) async {
    delete('playlist-folders/${folder.id}');
    _folders.remove(folder);
    notifyListeners();
  }

  Future<void> fetchAll() async {
    final res = await get('playlist-folders');
    _folders = (res as List)
        .map<PlaylistFolder>((j) => PlaylistFolder.fromJson(j))
        .toList();
    notifyListeners();
  }
}

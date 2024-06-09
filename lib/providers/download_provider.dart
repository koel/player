import 'dart:async';
import 'dart:io';

import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/utils/crypto.dart';
import 'package:app/utils/preferences.dart' as preferences;
import 'package:collection/collection.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';

class Download {
  final Playable playable;
  final String path;

  Download({required this.playable, required this.path});
}

class DownloadProvider with StreamSubscriber {
  final PlayableProvider _playableProvider;
  final _downloads = <Download>[];

  List<Playable> get playables => _downloads.map((d) => d.playable).toList();

  final _downloadsCleared = StreamController<bool>.broadcast();
  final _downloadRemoved = StreamController<Playable>.broadcast();
  final _playableDownloaded = StreamController<Download>.broadcast();

  Stream<bool> get downloadsClearedStream => _downloadsCleared.stream;

  Stream<Playable> get downloadRemovedStream => _downloadRemoved.stream;

  Stream<Download> get playableDownloadedStream => _playableDownloaded.stream;

  static const serializedPlayableContainer = 'Downloads';
  static final _playableStorage = GetStorage(serializedPlayableContainer);

  DownloadProvider({required PlayableProvider playableProvider})
      : _playableProvider = playableProvider {
    subscribe(AuthProvider.userLoggedOutStream.listen((_) {
      _downloads.clear();
    }));

    subscribe(AuthProvider.userLoggedInStream.listen((_) {
      // re-collect downloads when the user logs in (e.g., when there's a user
      // switch)
      _collectDownloads();
    }));

    _collectDownloads();
  }

  Future<String> get downloadsDir async {
    final documentsDir = await getApplicationDocumentsDirectory();

    final hash = sha256(
      '${preferences.host}${preferences.userEmail}'.toLowerCase(),
    );

    return '${documentsDir.path}/${hash}';
  }

  Future<void> _collectDownloads() async {
    _downloads.clear();
    final serializedPlayables =
        _playableStorage.read<List<dynamic>>(serializedPlayableKey) ?? [];

    var downloadsDir = await this.downloadsDir;

    serializedPlayables.forEach((json) {
      var playable = Playable.fromJson(json);
      final file = _localFile(downloadsDir, playable);

      if (file.existsSync() && !_downloads.any((d) => d.playable == playable)) {
        _downloads.add(Download(playable: playable, path: file.path));
      }
    });

    _playableProvider.syncWithVault(this.playables);
  }

  File _localFile(String downloadsDir, Playable playable) {
    // just_audio requires a valid extension on iOS
    // see https://github.com/ryanheise/just_audio/issues/289
    return File('${downloadsDir}/${playable.cacheKey}.mp3');
  }

  get serializedPlayableKey =>
      '${preferences.host}.${preferences.userEmail}.songs';

  Future<void> download({required Playable playable}) async {
    var client = HttpClient();
    var targetDir = Directory(await downloadsDir);

    if (!targetDir.existsSync()) {
      targetDir.createSync();
    }

    var file = _localFile(targetDir.path, playable);

    if (file.existsSync()) {
      try {
        file.deleteSync();
      } catch (e) {
        print(e);
      }
    }

    var request = await client.getUrl(Uri.parse(playable.sourceUrl));
    var response = await request.close();
    List<int> downloadData = [];

    response.listen((data) async {
      downloadData.addAll(data);
    }, onDone: () {
      file.writeAsBytesSync(downloadData);
      final download = Download(playable: playable, path: file.path);
      _playableStorage.write(
        serializedPlayableKey,
        playables
          ..add(playable)
          ..toSet()
          ..toList(),
      );

      _playableDownloaded.add(download);
      _downloads.add(download);
    }, onError: (error) {
      print(error);
    });
  }

  Download? getForPlayable(Playable playable) {
    return _downloads.firstWhereOrNull((d) => d.playable == playable);
  }

  bool has({required Playable playable}) => getForPlayable(playable) != null;

  Future<void> removeForPlayable(Playable playable) async {
    _removePlayable(playable);
    _downloadRemoved.add(playable);

    _downloads.removeWhere((element) => element.playable.id == playable.id);
    _playableStorage.write(serializedPlayableKey, playables..remove(playable));
  }

  Future<void> clear() async {
    await Future.forEach<Playable>(playables, (playable) async {
      await _removePlayable(playable);
    });

    _downloadsCleared.add(true);
    _downloads.clear();
    _playableStorage.remove(serializedPlayableKey);
  }

  Future<void> _removePlayable(Playable playable) async {
    var download = getForPlayable(playable);

    if (download == null) return;

    try {
      await File(download.path).delete();
    } catch (e) {
      print(e);
    }
  }
}

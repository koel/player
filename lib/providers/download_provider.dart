import 'dart:async';
import 'dart:io';

import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/utils/crypto.dart';
import 'package:get_storage/get_storage.dart';
import 'package:collection/collection.dart';
import 'package:app/utils/preferences.dart' as preferences;
import 'package:path_provider/path_provider.dart';

class Download {
  final Song song;
  final String path;

  Download({required this.song, required this.path});
}

class DownloadProvider with StreamSubscriber {
  final SongProvider _songProvider;
  final _downloads = <Download>[];

  List<Song> get songs => _downloads.map((d) => d.song).toList();

  final _downloadsCleared = StreamController<bool>.broadcast();
  final _downloadRemoved = StreamController<Song>.broadcast();
  final _songDownloaded = StreamController<Download>.broadcast();

  Stream<bool> get downloadsClearedStream => _downloadsCleared.stream;

  Stream<Song> get downloadRemovedStream => _downloadRemoved.stream;

  Stream<Download> get songDownloadedStream => _songDownloaded.stream;

  static const serializedSongContainer = 'Downloads';
  static final _songStorage = GetStorage(serializedSongContainer);

  DownloadProvider({required SongProvider songProvider})
      : _songProvider = songProvider {
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
    final hash =
        sha256('${preferences.host}${preferences.userEmail}'.toLowerCase());
    return '${documentsDir.path}/${hash}';
  }

  Future<void> _collectDownloads() async {
    _downloads.clear();
    final serializedSongs =
        _songStorage.read<List<dynamic>>(serializedSongKey) ?? [];

    var downloadsDir = await this.downloadsDir;

    serializedSongs.forEach((json) {
      var song = Song.fromJson(json);
      final file = _localFile(downloadsDir, song);

      if (file.existsSync() && !_downloads.any((d) => d.song == song)) {
        _downloads.add(Download(song: song, path: file.path));
      }
    });

    _songProvider.syncWithVault(this.songs);
  }

  File _localFile(String downloadsDir, Song song) {
    // just_audio requires a valid extension on iOS
    // see https://github.com/ryanheise/just_audio/issues/289
    return File('${downloadsDir}/${song.cacheKey}.mp3');
  }

  get serializedSongKey => '${preferences.host}.${preferences.userEmail}.songs';

  Future<void> download({required Song song}) async {
    var client = HttpClient();
    var targetDir = Directory(await downloadsDir);

    if (!targetDir.existsSync()) {
      targetDir.createSync();
    }

    var file = _localFile(targetDir.path, song);

    if (file.existsSync()) {
      try {
        file.deleteSync();
      } catch (e) {
        print(e);
      }
    }

    var request = await client.getUrl(Uri.parse(song.sourceUrl));
    var response = await request.close();
    List<int> downloadData = [];

    response.listen((data) async {
      downloadData.addAll(data);
    }, onDone: () {
      file.writeAsBytesSync(downloadData);
      final download = Download(song: song, path: file.path);
      _songStorage.write(
        serializedSongKey,
        songs
          ..add(song)
          ..toSet()
          ..toList(),
      );

      _songDownloaded.add(download);
      _downloads.add(download);
    }, onError: (error) {
      print(error);
    });
  }

  Download? getForSong(Song song) {
    return _downloads.firstWhereOrNull((d) => d.song == song);
  }

  bool has({required Song song}) => getForSong(song) != null;

  Future<void> removeForSong(Song song) async {
    _removeSong(song);
    _downloadRemoved.add(song);

    _downloads.removeWhere((element) => element.song.id == song.id);
    _songStorage.write(serializedSongKey, songs..remove(song));
  }

  Future<void> clear() async {
    await Future.forEach<Song>(songs, (song) async {
      await _removeSong(song);
    });

    _downloadsCleared.add(true);
    _downloads.clear();
    _songStorage.remove(serializedSongKey);
  }

  Future<void> _removeSong(Song song) async {
    var download = getForSong(song);

    if (download == null) return;

    try {
      await File(download.path).delete();
    } catch (e) {
      print(e);
    }
  }
}

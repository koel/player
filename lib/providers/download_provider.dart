import 'package:app/models/models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rxdart/rxdart.dart';
import 'package:collection/collection.dart';

class Download {
  final Song song;
  final FileInfo file;

  Download({required this.song, required this.file});
}

class DownloadProvider with ChangeNotifier {
  List<Download> _downloads = [];

  List<Song> get songs => _downloads.map((d) => d.song).toList();

  final BehaviorSubject<bool> _downloadsCleared = BehaviorSubject();

  ValueStream<bool> get downloadsClearedStream => _downloadsCleared.stream;

  final BehaviorSubject<Song> _singleDownloadRemoved = BehaviorSubject();

  ValueStream<Song> get singleCacheRemovedStream =>
      _singleDownloadRemoved.stream;

  final BehaviorSubject<Download> _songCached = BehaviorSubject();

  ValueStream<Download> get songDownloadedStream => _songCached.stream;

  static final serializedSongContainer = 'Downloads';
  static final serializedSongKey = 'songs';
  static const downloadCacheKey = 'koel.downloaded.songs';
  static final GetStorage _songStorage = GetStorage(serializedSongContainer);

  static final CacheManager _downloadManager = CacheManager(
    Config(
      downloadCacheKey,
      stalePeriod: Duration(days: 365 * 10),
    ),
  );

  Future<void> collectDownloads() async {
    var songs = _songStorage.read<List<dynamic>>(serializedSongKey) ?? [];

    await Future.forEach<dynamic>(songs, (json) async {
      Song song = Song.fromJson(json);
      var file = await _downloadManager.getFileFromCache(song.cacheKey);

      // a download is only valid if the file is still found in the cache
      // (i.e. it hasn't been deleted by the OS)
      if (file != null) {
        _downloads.add(Download(song: song, file: file));
      }
    });
  }

  Future<void> download({required Song song}) async {
    FileInfo file = await _downloadManager.downloadFile(
      song.sourceUrl,
      key: song.cacheKey,
      force: true,
    );

    var download = Download(song: song, file: file);
    _songStorage.write(
      'songs',
      songs
        ..add(song)
        ..toSet()
        ..toList(),
    );

    _songCached.add(download);
    _downloads.add(download);

    notifyListeners();
  }

  FileInfo? get({required Song song}) {
    return _downloads.firstWhereOrNull((element) => element.song == song)?.file;
  }

  bool has({required Song song}) => get(song: song) != null;

  Future<void> remove({required Song song}) async {
    await _downloadManager.removeFile(song.cacheKey);
    _singleDownloadRemoved.add(song);

    _downloads.removeWhere((element) => element.song.id == song.id);

    _songStorage.write(
      serializedSongKey,
      songs..removeWhere((s) => s.id == song.id),
    );

    notifyListeners();
  }

  Future<void> clear() async {
    await _downloadManager.emptyCache();
    _downloadsCleared.add(true);
    _downloads.clear();
    _songStorage.erase();

    notifyListeners();
  }
}

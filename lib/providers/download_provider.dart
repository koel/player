import 'dart:async';

import 'package:app/models/models.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get_storage/get_storage.dart';
import 'package:collection/collection.dart';

class Download {
  final Song song;
  final FileInfo file;

  Download({required this.song, required this.file});
}

class DownloadProvider {
  final _downloads = <Download>[];

  List<Song> get songs => _downloads.map((d) => d.song).toList();

  final _downloadsCleared = StreamController<bool>.broadcast();
  final _downloadRemoved = StreamController<Song>.broadcast();
  final _songDownloaded = StreamController<Download>.broadcast();

  Stream<bool> get downloadsClearedStream => _downloadsCleared.stream;

  Stream<Song> get downloadRemovedStream => _downloadRemoved.stream;

  Stream<Download> get songDownloadedStream => _songDownloaded.stream;

  static const serializedSongContainer = 'Downloads';
  static const serializedSongKey = 'songs';
  static const downloadCacheKey = 'koel.downloaded.songs';
  static final _songStorage = GetStorage(serializedSongContainer);

  static final _downloadManager = CacheManager(
    Config(
      downloadCacheKey,
      stalePeriod: Duration(days: 365 * 10),
    ),
  );

  Future<void> collectDownloads() async {
    final songs = _songStorage.read<List<dynamic>>(serializedSongKey) ?? [];

    await Future.forEach<dynamic>(songs, (json) async {
      var song = Song.fromJson(json);
      final file = await _downloadManager.getFileFromCache(song.cacheKey);

      // a download is only valid if the file is still found in the cache
      // (i.e. it hasn't been deleted by the OS)
      if (file != null) {
        _downloads.add(Download(song: song, file: file));
      }
    });
  }

  Future<void> download({required Song song}) async {
    final file = await _downloadManager.downloadFile(
      song.sourceUrl,
      key: song.cacheKey,
      force: true,
    );

    final download = Download(song: song, file: file);
    _songStorage.write(
      'songs',
      songs
        ..add(song)
        ..toSet()
        ..toList(),
    );

    _songDownloaded.add(download);
    _downloads.add(download);
  }

  FileInfo? getForSong(Song song) {
    return _downloads.firstWhereOrNull((d) => d.song == song)?.file;
  }

  bool has({required Song song}) => getForSong(song) != null;

  Future<void> removeForSong(Song song) async {
    await _downloadManager.removeFile(song.cacheKey);
    _downloadRemoved.add(song);

    _downloads.removeWhere((element) => element.song.id == song.id);
    _songStorage.write(serializedSongKey, songs..remove(song));
  }

  Future<void> clear() async {
    await _downloadManager.emptyCache();
    _downloadsCleared.add(true);
    _downloads.clear();
    _songStorage.erase();
  }
}

import 'package:app/models/song.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:rxdart/rxdart.dart';

class SongCached {
  final Song song;
  final FileInfo info;

  SongCached({required this.song, required this.info});
}

class CacheProvider with ChangeNotifier {
  List<Song> songs = [];

  final BehaviorSubject<bool> _cacheCleared = BehaviorSubject();
  ValueStream<bool> get cacheClearedStream => _cacheCleared.stream;

  final BehaviorSubject<Song> _singleCacheRemoved = BehaviorSubject();
  ValueStream<Song> get singleCacheRemovedStream => _singleCacheRemoved.stream;

  final BehaviorSubject<SongCached> _songCached = BehaviorSubject();
  ValueStream<SongCached> get songCachedStream => _songCached.stream;

  static CacheManager _cache = DefaultCacheManager();

  Future<void> cache({required Song song}) async {
    FileInfo fileInfo = await _cache.downloadFile(
      song.sourceUrl,
      key: song.cacheKey,
      force: true,
    );

    _songCached.add(SongCached(song: song, info: fileInfo));
    songs.add(song);
    notifyListeners();
  }

  Future<FileInfo?> get({required Song song}) async {
    return await _cache.getFileFromCache(song.cacheKey);
  }

  Future<bool> has({required Song song}) async {
    return await this.get(song: song) != null;
  }

  Future<void> remove({required Song song}) async {
    await _cache.removeFile(song.cacheKey);
    _singleCacheRemoved.add(song);
    this.songs.remove(song);
    notifyListeners();
  }

  Future<void> clear() async {
    await _cache.emptyCache();
    _cacheCleared.add(true);
    this.songs.clear();
    notifyListeners();
  }
}

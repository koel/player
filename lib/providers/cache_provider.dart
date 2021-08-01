import 'package:app/models/song.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:rxdart/rxdart.dart';

class SongCached {
  final Song song;
  final FileInfo info;

  SongCached({required this.song, required this.info});
}

class CacheProvider {
  final BehaviorSubject<bool> _cacheCleared = BehaviorSubject();

  ValueStream<bool> get cacheClearedStream => _cacheCleared.stream;

  final BehaviorSubject<SongCached> _songMediaCached = BehaviorSubject();

  ValueStream<SongCached> get songCachedStream => _songMediaCached.stream;

  static CacheManager _cache = DefaultCacheManager();

  Future<void> cache({required Song song}) async {
    FileInfo fileInfo = await _cache.downloadFile(
      song.sourceUrl,
      key: song.cacheKey,
      force: true,
    );

    _songMediaCached.add(SongCached(song: song, info: fileInfo));
  }

  Future<FileInfo?> getCache({required Song song}) async {
    return await _cache.getFileFromCache(song.cacheKey);
  }

  Future<bool> hasCache({required Song song}) async {
    return await this.getCache(song: song) != null;
  }

  Future<void> clear() async {
    await _cache.emptyCache();
    _cacheCleared.add(true);
  }
}

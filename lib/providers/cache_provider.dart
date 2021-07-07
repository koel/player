import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:rxdart/rxdart.dart';

class CacheProvider {
  BehaviorSubject<bool> _cacheCleared = BehaviorSubject();
  ValueStream<bool> get cacheClearedStream => _cacheCleared.stream;

  Future<void> clear() async {
    await DefaultCacheManager().emptyCache();
    _cacheCleared.add(true);
  }
}

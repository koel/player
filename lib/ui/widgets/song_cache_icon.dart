import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/cache_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SongCacheIcon extends StatefulWidget {
  final Song song;

  const SongCacheIcon({Key? key, required this.song}) : super(key: key);

  @override
  _SongCacheIconState createState() => _SongCacheIconState();
}

class _SongCacheIconState extends State<SongCacheIcon> with StreamSubscriber {
  late CacheProvider cache;
  bool _downloading = false;
  bool? _hasCache;

  @override
  void initState() {
    super.initState();
    cache = context.read();

    subscribe(cache.cacheClearedStream.listen((_) {
      setState(() => _hasCache = false);
    }));

    subscribe(cache.songCachedStream.listen((event) {
      if (event.song == widget.song) {
        setState(() => _hasCache = true);
      }
    }));

    cache.hasCache(song: widget.song).then((value) {
      setState(() => _hasCache = value);
    });
  }

  @override
  void dispose() {
    unsubscribeAll();
    super.dispose();
  }

  Future<void> _cache() async {
    setState(() => _downloading = true);
    await cache.cache(song: widget.song);
    setState(() {
      _downloading = false;
      _hasCache = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_downloading) return CupertinoActivityIndicator(radius: 9);

    if (_hasCache == null) return SizedBox.shrink();

    if (_hasCache!) {
      return Icon(
        CupertinoIcons.checkmark_alt_circle_fill,
        size: 18,
        color: Colors.white24,
      );
    }

    return GestureDetector(
      onTap: () async => await _cache(),
      child: const Icon(
        CupertinoIcons.cloud_download_fill,
        size: 16,
      ),
    );
  }
}

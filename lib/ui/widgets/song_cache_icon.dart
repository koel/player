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

    subscribe(cache.singleCacheRemovedStream.listen((song) {
      if (song == widget.song) {
        setState(() => _hasCache = false);
      }
    }));

    subscribe(cache.songCachedStream.listen((event) {
      if (event.song == widget.song) {
        setState(() => _hasCache = true);
      }
    }));

    cache.has(song: widget.song).then((value) {
      setState(() => _hasCache = value);
    });
  }

  /// Since this widget is rendered inside NowPlayingScreen, change to current
  /// song in the parent will not trigger initState() and as a result not
  /// refresh the song's cache status.
  /// For that, we hook into didUpdateWidget().
  /// See https://stackoverflow.com/questions/54759920/flutter-why-is-child-widgets-initstate-is-not-called-on-every-rebuild-of-pa.
  @override
  void didUpdateWidget(covariant SongCacheIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resolveCacheStatus();
  }

  Future<void> _resolveCacheStatus() async {
    bool hasState = await cache.has(song: widget.song);
    setState(() => _hasCache = hasState);
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
    if (_downloading)
      return const Padding(
        padding: EdgeInsets.only(right: 4.0),
        child: CupertinoActivityIndicator(radius: 9),
      );

    if (_hasCache == null) return const SizedBox.shrink();

    if (_hasCache!) {
      return const Padding(
        padding: EdgeInsets.only(right: 4.0),
        child: Icon(
          CupertinoIcons.checkmark_alt_circle_fill,
          size: 18,
          color: Colors.white24,
        ),
      );
    }

    return IconButton(
      onPressed: () async => await _cache(),
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.symmetric(horizontal: 0.0),
      icon: const Icon(
        CupertinoIcons.cloud_download_fill,
        size: 16,
      ),
    );
  }
}

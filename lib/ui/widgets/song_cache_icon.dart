import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/cache_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:provider/provider.dart';

class SongCacheIcon extends StatefulWidget {
  final Song song;

  const SongCacheIcon({Key? key, required this.song}) : super(key: key);

  @override
  _SongCacheIconState createState() => _SongCacheIconState();
}

class _SongCacheIconState extends State<SongCacheIcon> with StreamSubscriber {
  late CacheProvider cache;
  late Future<FileInfo?> _futureCachedFile;
  bool _downloading = false;

  void triggerCacheState() {
    setState(() {
      _futureCachedFile = DefaultCacheManager().getFileFromCache(
        widget.song.cacheKey,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    cache = context.read();

    subscribe(cache.cacheClearedStream.listen((_) => triggerCacheState()));

    triggerCacheState();
  }

  @override
  void dispose() {
    unsubscribeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FileInfo?>(
      future: _futureCachedFile,
      builder: (_, snapshot) {
        if (snapshot.hasData) {
          return Icon(
            CupertinoIcons.checkmark_alt_circle_fill,
            size: 18,
            color: Colors.white24,
          );
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox.shrink();
        }

        return _downloading
            ? CupertinoActivityIndicator(radius: 9)
            : GestureDetector(
                onTap: () async {
                  setState(() => _downloading = true);
                  await widget.song.cacheSourceFile();
                  setState(() => _downloading = false);
                  // trigger getting cache to re-determine _futureCachedFile's status
                  // and rebuild the widget
                  triggerCacheState();
                },
                child: const Icon(
                  CupertinoIcons.cloud_download_fill,
                  size: 16,
                ),
              );
      },
    );
  }
}

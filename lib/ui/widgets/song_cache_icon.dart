import 'package:app/models/song.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class SongCacheIcon extends StatefulWidget {
  final Song song;

  const SongCacheIcon({Key? key, required this.song}) : super(key: key);

  @override
  _SongCacheIconState createState() => _SongCacheIconState();
}

class _SongCacheIconState extends State<SongCacheIcon> {
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
    triggerCacheState();
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
            color: Colors.white.withOpacity(.2),
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

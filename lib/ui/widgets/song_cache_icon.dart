import 'package:app/constants/colors.dart';
import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
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
  late DownloadProvider downloadProvider;
  var _downloading = false;
  bool? _downloaded;

  @override
  void initState() {
    super.initState();
    downloadProvider = context.read();

    subscribe(downloadProvider.downloadsClearedStream.listen((_) {
      setState(() => _downloaded = false);
    }));

    subscribe(downloadProvider.downloadRemovedStream.listen((song) {
      if (song == widget.song) setState(() => _downloaded = false);
    }));

    subscribe(downloadProvider.songDownloadedStream.listen((event) {
      if (event.song == widget.song) setState(() => _downloaded = true);
    }));

    setState(() => _downloaded = downloadProvider.has(song: widget.song));
  }

  /// Since this widget is rendered inside NowPlayingScreen, change to current
  /// song in the parent will not trigger initState() and as a result not
  /// refresh the song's cache status.
  /// For that, we hook into didUpdateWidget().
  /// See https://stackoverflow.com/questions/54759920/flutter-why-is-child-widgets-initstate-is-not-called-on-every-rebuild-of-pa.
  @override
  void didUpdateWidget(covariant SongCacheIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resolveDownloadStatus();
  }

  void _resolveDownloadStatus() {
    setState(() => _downloaded = downloadProvider.has(song: widget.song));
  }

  @override
  void dispose() {
    unsubscribeAll();
    super.dispose();
  }

  Future<void> _download() async {
    setState(() => _downloading = true);
    await downloadProvider.download(song: widget.song);
    setState(() {
      _downloading = false;
      _downloaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_downloading)
      return const Padding(
        padding: EdgeInsets.only(right: 4.0),
        child: CupertinoActivityIndicator(
          radius: 9,
          color: AppColors.white,
        ),
      );

    final downloaded = this._downloaded;

    if (downloaded == null) return const SizedBox.shrink();

    if (downloaded) {
      return const Padding(
        padding: EdgeInsets.only(right: 4.0),
        child: Icon(
          CupertinoIcons.checkmark_alt_circle_fill,
          size: 18,
          color: AppColors.green,
        ),
      );
    }

    return IconButton(
      onPressed: _download,
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.symmetric(horizontal: 0.0),
      icon: const Icon(
        CupertinoIcons.cloud_download_fill,
        size: 16,
      ),
    );
  }
}

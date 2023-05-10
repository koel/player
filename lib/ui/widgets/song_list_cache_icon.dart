import 'package:app/constants/constants.dart';
import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SongListCacheIcon extends StatefulWidget {
  final List<Song> songs;

  const SongListCacheIcon({Key? key, required this.songs}) : super(key: key);

  @override
  _SongListCacheIconState createState() => _SongListCacheIconState();
}

class _SongListCacheIconState extends State<SongListCacheIcon>
    with StreamSubscriber {
  late DownloadProvider downloadProvider;
  var _downloading = false;
  bool? _downloaded = false;

  static const downloadBatchSize = 3;

  @override
  void initState() {
    super.initState();
    downloadProvider = context.read();

    subscribe(downloadProvider.downloadsClearedStream.listen((_) {
      setState(() => _downloaded = false);
    }));

    subscribe(downloadProvider.downloadRemovedStream.listen((song) {
      if (widget.songs.contains(song)) setState(() => _downloaded = false);
    }));

    subscribe(downloadProvider.songDownloadedStream.listen((event) {
      if (widget.songs.contains(event.song)) _resolveDownloadStatus();
    }));

    _resolveDownloadStatus();
  }

  /// Since this widget is rendered inside NowPlayingScreen, change to current
  /// song in the parent will not trigger initState() and as a result not
  /// refresh the song's cache status.
  /// For that, we hook into didUpdateWidget().
  /// See https://stackoverflow.com/questions/54759920/flutter-why-is-child-widgets-initstate-is-not-called-on-every-rebuild-of-pa.
  @override
  void didUpdateWidget(covariant SongListCacheIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resolveDownloadStatus();
  }

  void _resolveDownloadStatus() {
    setState(() => _downloaded =
        !widget.songs.any((song) => !downloadProvider.has(song: song)));
  }

  @override
  void dispose() {
    unsubscribeAll();
    super.dispose();
  }

  Future<void> _download() async {
    setState(() => _downloading = true);

    int indexLastStarted = 0;

    /// Download songs in parallel.
    /// Recursively iterates over the song list, downloading songs that haven't
    /// been downloaded yet.
    Future<void> downloadNextSong() async {
      if (indexLastStarted >= widget.songs.length) return;

      Song song;
      do {
        song = widget.songs[indexLastStarted++];
      } while (downloadProvider.has(song: song) &&
          indexLastStarted < widget.songs.length);

      await downloadProvider.download(song: song);
      await downloadNextSong();
    }

    await Future.wait(
        List.generate(downloadBatchSize, (_) => downloadNextSong()));

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
        child: CupertinoActivityIndicator(radius: 9, color: AppColors.white),
      );

    final downloaded = this._downloaded;

    if (downloaded == null) return const SizedBox.shrink();

    if (downloaded) {
      return const Padding(
        padding: EdgeInsets.only(right: 4.0),
        child: Icon(
          CupertinoIcons.checkmark_alt_circle_fill,
          size: 18,
          color: Color(0xFFFAD763),
        ),
      );
    }

    return IconButton(
      onPressed: _download,
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.symmetric(horizontal: 0.0),
      icon: const Icon(CupertinoIcons.cloud_download_fill, size: 16),
    );
  }
}

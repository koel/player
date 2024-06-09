import 'package:app/constants/constants.dart';
import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlayableCacheIcon extends StatefulWidget {
  final Playable playable;

  const PlayableCacheIcon({Key? key, required this.playable}) : super(key: key);

  @override
  _PlayableCacheIconState createState() => _PlayableCacheIconState();
}

class _PlayableCacheIconState extends State<PlayableCacheIcon>
    with StreamSubscriber {
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

    subscribe(downloadProvider.downloadRemovedStream.listen((playable) {
      if (playable == widget.playable) setState(() => _downloaded = false);
    }));

    subscribe(downloadProvider.playableDownloadedStream.listen((event) {
      if (event.playable == widget.playable) setState(() => _downloaded = true);
    }));

    setState(
      () => _downloaded = downloadProvider.has(playable: widget.playable),
    );
  }

  /// Since this widget is rendered inside NowPlayingScreen, change to current
  /// song in the parent will not trigger initState() and as a result not
  /// refresh the song's cache status.
  /// For that, we hook into didUpdateWidget().
  /// See https://stackoverflow.com/questions/54759920/flutter-why-is-child-widgets-initstate-is-not-called-on-every-rebuild-of-pa.
  @override
  void didUpdateWidget(covariant PlayableCacheIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resolveDownloadStatus();
  }

  void _resolveDownloadStatus() {
    setState(() => _downloaded = downloadProvider.has(
          playable: widget.playable,
        ));
  }

  @override
  void dispose() {
    unsubscribeAll();
    super.dispose();
  }

  Future<void> _download() async {
    setState(() => _downloading = true);
    await downloadProvider.download(playable: widget.playable);
    setState(() {
      _downloading = false;
      _downloaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    late final Widget icon;
    VoidCallback? action = null;

    if (_downloading) {
      icon = CupertinoActivityIndicator(radius: 9, color: AppColors.white);
    } else if (this._downloaded == true) {
      icon = Icon(
        CupertinoIcons.checkmark_alt_circle_fill,
        size: 18,
        color: Color(0xFFFAD763),
      );
    } else {
      icon = Icon(CupertinoIcons.cloud_download_fill, size: 16);
      action = _download;
    }

    return IconButton(onPressed: action, icon: icon);
  }
}

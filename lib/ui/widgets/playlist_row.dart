import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/screens/screens.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlaylistRow extends StatefulWidget {
  final Playlist playlist;

  final void Function()? onTap;

  const PlaylistRow({Key? key, required this.playlist, this.onTap})
      : super(key: key);

  _PlaylistRowState createState() => _PlaylistRowState();
}

class _PlaylistRowState extends State<PlaylistRow> with StreamSubscriber {
  late final PlaylistProvider playlistProvider;
  late Playlist _playlist;

  @override
  initState() {
    super.initState();
    playlistProvider = context.read();
    setState(() => _playlist = widget.playlist);
  }

  void _defaultOnTap() => gotoDetailsScreen(context, playlist: _playlist);

  @override
  Widget build(BuildContext context) {
    final subtitle = _playlist.isSmart ? 'Smart playlist' : 'Standard playlist';

    return InkWell(
      onTap: widget.onTap ?? _defaultOnTap,
      child: ListTile(
        shape: Border(bottom: Divider.createBorderSide(context)),
        leading: PlaylistThumbnail(playlist: _playlist),
        title: Text(_playlist.name, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class PlaylistThumbnail extends StatelessWidget {
  final Playlist playlist;

  const PlaylistThumbnail({Key? key, required this.playlist}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Icon(
      CupertinoIcons.music_note_list,
      color: Colors.white54,
    );
  }
}

import 'dart:async';

import 'package:app/models/playlist.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/playlist_provider.dart';
import 'package:app/ui/screens/playlist_details.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlaylistRow extends StatefulWidget {
  final Playlist playlist;

  final VoidCallback? onTap;

  PlaylistRow({Key? key, required this.playlist, this.onTap}) : super(key: key);

  _PlaylistRowState createState() => _PlaylistRowState();
}

class _PlaylistRowState extends State<PlaylistRow> {
  late final PlaylistProvider playlistProvider;
  List<StreamSubscription> _subscriptions = [];
  late Playlist _playlist;

  @override
  initState() {
    super.initState();
    playlistProvider = context.read();
    setState(() => _playlist = widget.playlist);

    _subscriptions.add(
      playlistProvider.playlistPopulatedStream.listen((playlist) {
        if (playlist.id == _playlist.id) {
          setState(() => _playlist = playlist);
        }
      }),
    );
  }

  dispose() {
    _subscriptions.forEach((subscription) => subscription.cancel());
    super.dispose();
  }

  Widget playlistThumbnail() {
    late ImageProvider thumbnail;

    if (!_playlist.isEmpty) {
      Song songWithCustomImage = _playlist.songs.firstWhere((song) {
        return song.image is NetworkImage &&
            !(song.image as NetworkImage).url.endsWith('/unknown-album.png');
      }, orElse: () => _playlist.songs[0]);

      thumbnail = songWithCustomImage.image;
    } else {
      thumbnail = AssetImage('assets/images/unknown-album.png');
    }

    return SizedBox(
      width: 40,
      height: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(6)),
          image: _playlist.populated
              ? DecorationImage(image: thumbnail, fit: BoxFit.cover)
              : null,
        ),
        child: _playlist.populated
            ? SizedBox.shrink()
            : Opacity(
                opacity: .5,
                child: Icon(CupertinoIcons.music_note_list),
              ),
      ),
    );
  }

  void _defaultOnTap () => gotoDetailsScreen(context, playlist: _playlist);

  @override
  Widget build(BuildContext context) {
    String subtitle =
        _playlist.isSmart ? 'Smart playlist' : 'Standard playlist';

    if (_playlist.populated) {
      subtitle += _playlist.isEmpty
          ? ' • Empty'
          : ' • ${_playlist.songs.length} song' +
              (_playlist.songs.length == 1 ? '' : 's');
    }

    return InkWell(
      onTap: widget.onTap ?? _defaultOnTap,
      child: ListTile(
        shape: Border(bottom: Divider.createBorderSide(context)),
        leading: playlistThumbnail(),
        title: Text(_playlist.name, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle),
      ),
    );
  }
}

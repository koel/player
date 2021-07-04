import 'package:app/constants/dimens.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/audio_player_provider.dart';
import 'package:app/ui/widgets/song_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum SongListBehavior { queue, none }

class SongList extends StatefulWidget {
  final List<Song> songs;
  final ScrollController? controller;

  SongList({
    Key? key,
    required this.songs,
    this.controller,
  }) : super(key: key);

  @override
  _SongListState createState() => _SongListState();
}

class _SongListState extends State<SongList> {
  late AudioPlayerProvider audio;

  @override
  void initState() {
    super.initState();
    audio = context.read();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: widget.controller ?? ScrollController(),
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: widget.songs.length,
      itemBuilder: (BuildContext context, int index) {
        return SongRow(song: widget.songs[index]);
      },
    );
  }
}

Widget _songListButton({
  required IconData icon,
  required String label,
  required VoidCallback onPressed,
}) {
  return Expanded(
    child: ConstrainedBox(
      constraints: BoxConstraints.expand(
        width: double.infinity,
        height: 48,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          primary: Colors.grey.shade900,
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        onPressed: onPressed,
        child: Row(
          children: <Widget>[
            Icon(icon, size: 20),
            Expanded(
              child: Text(label, textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget songListButtons(BuildContext context, {required List<Song> songs}) {
  AudioPlayerProvider audio = context.read();
  return Container(
    padding: EdgeInsets.all(AppDimens.horizontalPadding),
    child: Row(
      children: <Widget>[
        _songListButton(
          icon: CupertinoIcons.play_fill,
          label: 'Play All',
          onPressed: () async => await audio.replaceQueue(songs),
        ),
        SizedBox(width: 12),
        _songListButton(
          icon: CupertinoIcons.shuffle,
          label: 'Shuffle All',
          onPressed: () async => await audio.replaceQueue(songs, shuffle: true),
        ),
      ],
    ),
  );
}

import 'package:app/models/song.dart';
import 'package:app/providers/audio_player_provider.dart';
import 'package:app/ui/widgets/song_row.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum SongListBehavior { queue, none }

class SongList extends StatefulWidget {
  final List<Song> songs;
  final SongListBehavior behavior;
  final ScrollController? controller;

  SongList({
    Key? key,
    required this.songs,
    this.behavior = SongListBehavior.none,
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
    audio = context.read<AudioPlayerProvider>();
  }

  @override
  Widget build(BuildContext context) {
    return widget.behavior == SongListBehavior.queue
        ? queue()
        : ListView.builder(
            controller: widget.controller ?? ScrollController(),
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: widget.songs.length,
            itemBuilder: (BuildContext context, int index) {
              return SongRow(
                song: widget.songs[index],
                behavior: widget.behavior,
              );
            },
          );
  }

  ReorderableListView queue() {
    return ReorderableListView.builder(
      scrollController: widget.controller ?? ScrollController(),
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: widget.songs.length,
      itemBuilder: (BuildContext context, int index) {
        return Dismissible(
          key: ValueKey(widget.songs[index]),
          child: SongRow(
            song: widget.songs[index],
            behavior: widget.behavior,
          ),
          onDismissed: (DismissDirection direction) {
            audio.removeFromQueue(widget.songs[index]);
          },
          background: Container(color: Colors.red),
        );
      },
      onReorder: (int oldIndex, int newIndex) {
        audio.reorderQueue(oldIndex, newIndex);
      },
    );
  }
}

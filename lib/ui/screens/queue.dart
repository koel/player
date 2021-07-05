import 'dart:async';

import 'package:app/models/song.dart';
import 'package:app/providers/audio_player_provider.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/song_list.dart';
import 'package:app/ui/widgets/song_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({Key? key}) : super(key: key);

  @override
  _QueueState createState() => _QueueState();
}

class _QueueState extends State<QueueScreen> {
  late AudioPlayerProvider audio;
  List<Song> _songs = [];
  List<StreamSubscription> subscriptions = [];

  @override
  void initState() {
    super.initState();
    audio = context.read<AudioPlayerProvider>();
    subscriptions.add(audio.queueModifiedStream.listen((_) {
      setState(() => _songs = audio.queuedSongs);
    }));
  }

  @override
  void dispose() {
    subscriptions.forEach((sub) => sub.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();

    return Scaffold(
      body: CustomScrollView(
        controller: scrollController,
        slivers: <Widget>[
          CupertinoSliverNavigationBar(
            backgroundColor: Colors.black,
            largeTitle: Text(
              'Current Queue',
              style: TextStyle(color: Colors.white),
            ),
            trailing: TextButton(
              onPressed: () => audio.clearQueue(),
              child: Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          ),
          _songs.length == 0
              ? SliverToBoxAdapter(
                  child: Column(
                    children: <Widget>[
                      SizedBox(height: 128),
                      Center(
                        child: Text(
                          'No songs queued.',
                          style: TextStyle(color: Colors.white.withOpacity(.5)),
                        ),
                      ),
                    ],
                  ),
                )
              : SliverReorderableList(
                  itemCount: _songs.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Dismissible(
                      direction: DismissDirection.endToStart,
                      onDismissed: (DismissDirection direction) =>
                          audio.removeFromQueue(song: _songs[index]),
                      background: Container(
                        alignment: AlignmentDirectional.centerEnd,
                        color: Colors.red,
                        child: Padding(
                          padding: EdgeInsets.only(right: 16),
                          child: Icon(CupertinoIcons.delete_simple),
                        ),
                      ),
                      key: ValueKey(_songs[index]),
                      child: SongRow(
                        index: index,
                        key: ValueKey(_songs[index]),
                        song: _songs[index],
                        behavior: SongListBehavior.queue,
                      ),
                    );
                  },
                  onReorder: (int oldIndex, int newIndex) {
                    audio.reorderQueue(oldIndex, newIndex);
                  },
                ),
          SliverToBoxAdapter(child: bottomSpace()),
        ],
      ),
    );
  }
}

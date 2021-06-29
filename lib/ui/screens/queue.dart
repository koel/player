import 'package:app/models/song.dart';
import 'package:app/providers/audio_player_provider.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/song_list.dart';
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

  @override
  void initState() {
    super.initState();
    audio = context.read<AudioPlayerProvider>();
    setState(() => _songs = audio.getQueuedSongs(context));
  }

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();

    return Scaffold(
      body: CustomScrollView(
        controller: scrollController,
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  audio.clearQueue();
                  setState(() => _songs = []);
                },
                child: Text('Clear', style: TextStyle(color: Colors.red)),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Current Queue'),
            ),
          ),
          _songs.length == 0
              ? SliverToBoxAdapter(
                  child: Column(
                    children: <Widget>[
                      SizedBox(height: 128),
                      Center(
                        child: Opacity(
                          opacity: .5,
                          child: Text('No songs queued.'),
                        ),
                      ),
                    ],
                  ),
                )
              : SliverToBoxAdapter(
                  child: SongList(
                    songs: _songs,
                    behavior: SongListBehavior.queue,
                    controller: scrollController,
                  ),
                ),
          SliverToBoxAdapter(child: bottomSpace()),
        ],
      ),
    );
  }
}

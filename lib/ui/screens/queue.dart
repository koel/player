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
  @override
  Widget build(BuildContext context) {
    AudioPlayerProvider audio = context.watch<AudioPlayerProvider>();
    List<Song> songs = audio.getQueuedSongs(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Current Queue'),
            ),
          ),
          songs.length == 0
              ? SliverToBoxAdapter(
                  child: Center(child: Text('No songs queued.')),
                )
              : SongList(songs: songs),
          SliverToBoxAdapter(child: bottomSpace()),
        ],
      ),
    );
  }
}

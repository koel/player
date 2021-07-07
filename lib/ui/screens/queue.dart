import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/audio_player_provider.dart';
import 'package:app/ui/widgets/app_bar.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/song_list.dart';
import 'package:app/ui/widgets/song_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide AppBar;
import 'package:provider/provider.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({Key? key}) : super(key: key);

  @override
  _QueueState createState() => _QueueState();
}

class _QueueState extends State<QueueScreen> with StreamSubscriber {
  late AudioPlayerProvider audio;
  List<Song> _songs = [];

  @override
  void initState() {
    super.initState();
    audio = context.read();
    subscribe(audio.queueModifiedStream.listen((_) {
      setState(() => _songs = audio.queuedSongs);
    }));
  }

  @override
  void dispose() {
    unsubscribeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          AppBar(
            headingText: 'Current Queue',
            coverImage: CoverImageStack(songs: _songs),
            actions: <Widget>[
              if (_songs.isNotEmpty)
                TextButton(
                  onPressed: () => audio.clearQueue(),
                  child: const Text(
                    'Clear',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
          if (_songs.isEmpty)
            SliverToBoxAdapter(
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 128),
                  Center(
                    child: const Text(
                      'No songs queued.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ],
              ),
            )
          else
            SliverReorderableList(
              itemCount: _songs.length,
              itemBuilder: (BuildContext context, int index) {
                return Dismissible(
                  direction: DismissDirection.endToStart,
                  onDismissed: (DismissDirection direction) =>
                      audio.removeFromQueue(song: _songs[index]),
                  background: Container(
                    alignment: AlignmentDirectional.centerEnd,
                    color: Colors.red,
                    child: const Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(CupertinoIcons.delete_simple),
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

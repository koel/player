import 'package:app/main.dart';
import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/widgets/app_bar.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/song_list_header.dart';
import 'package:app/ui/widgets/song_row.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide AppBar;
import 'package:provider/provider.dart';

class QueueScreen extends StatefulWidget {
  static const routeName = '/queue';

  const QueueScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> with StreamSubscriber {
  late SongProvider _songProvider;
  List<Song> _songs = [];

  @override
  void initState() {
    super.initState();
    _songProvider = context.read();

    subscribe(
      audioHandler.queue.listen((List<MediaItem> value) {
        setState(() {
          _songs = value.map((item) => _songProvider.byId(item.id)!).toList();
        });
      }),
    );
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
                  onPressed: audioHandler.clearQueue,
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
                      style: const TextStyle(color: Colors.white54),
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
                  onDismissed: (_) => audioHandler.removeQueueItemAt(index),
                  background: Container(
                    alignment: AlignmentDirectional.centerEnd,
                    color: Colors.red,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: Icon(CupertinoIcons.delete_simple),
                    ),
                  ),
                  key: ValueKey(_songs[index]),
                  child: SongRow(
                    index: index,
                    key: ValueKey(_songs[index]),
                    song: _songs[index],
                    listContext: SongListContext.queue,
                  ),
                );
              },
              onReorder: audioHandler.moveQueueItem,
            ),
          const BottomSpace(),
        ],
      ),
    );
  }
}

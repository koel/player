import 'package:app/main.dart';
import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/widgets/widgets.dart';
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
  late PlayableProvider _playableProvider;
  var _playables = <Playable>[];

  @override
  void initState() {
    super.initState();
    _playableProvider = context.read();

    subscribe(
      audioHandler.queue.listen((List<MediaItem> value) {
        setState(() {
          _playables =
              value.map((item) => _playableProvider.byId(item.id)!).toList();
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
      body: GradientDecoratedContainer(
        child: CustomScrollView(
          slivers: <Widget>[
            AppBar(
              headingText: 'Current Queue',
              coverImage: CoverImageStack(playables: _playables),
              actions: <Widget>[
                if (_playables.isNotEmpty)
                  TextButton(
                    onPressed: () async => await audioHandler.clearQueue(),
                    child: const Text(
                      'Clear',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
            if (_playables.isEmpty)
              SliverToBoxAdapter(
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 128),
                    Center(
                      child: const Text(
                        'No items queued.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ],
                ),
              )
            else
              SliverReorderableList(
                itemCount: _playables.length,
                itemBuilder: (BuildContext context, int index) {
                  return Dismissible(
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) async {
                      await audioHandler.removeQueueItemAt(index);
                    },
                    background: Container(
                      alignment: AlignmentDirectional.centerEnd,
                      color: Colors.red,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 16),
                        child: Icon(CupertinoIcons.delete),
                      ),
                    ),
                    key: ValueKey(_playables[index]),
                    child: PlayableRow(
                      index: index,
                      key: ValueKey(_playables[index]),
                      playable: _playables[index],
                      listContext: PlayableListContext.queue,
                    ),
                  );
                },
                onReorder: audioHandler.moveQueueItem,
              ),
            const BottomSpace(),
          ],
        ),
      ),
    );
  }
}

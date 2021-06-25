import 'package:app/providers/song_provider.dart';
import 'package:app/ui/widgets/song_row.dart';
import 'package:audio_service/audio_service.dart';
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
    return StreamBuilder<List<MediaItem>?>(
      stream: AudioService.queueStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: Text('Queue is empty'),
          );
        }

        SongProvider songProvider = Provider.of<SongProvider>(context);

        return ListView.builder(
          shrinkWrap: false,
          itemBuilder: (BuildContext context, int index) {
            return SongRow(
              song: songProvider.byId(
                snapshot.data!.elementAt(index).extras!['songId'],
              ),
            );
          },
          itemCount: snapshot.data!.length,
        );
      },
    );
  }
}

import 'package:app/providers/audio_player_provider.dart';
import 'package:app/providers/song_provider.dart';
import 'package:app/ui/widgets/song_row.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
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
    Playlist playlist = context.watch<AudioPlayerProvider>().player.playlist!;
    SongProvider songProvider = context.watch<SongProvider>();

    return ListView.builder(
      shrinkWrap: false,
      itemBuilder: (BuildContext context, int index) {
        return SongRow(
          song:
              songProvider.byId(playlist.audios[index].metas.extra!['songId']),
          padding: EdgeInsets.symmetric(horizontal: 0),
        );
      },
      itemCount: playlist.numberOfItems,
    );
  }
}

import 'package:app/app_state.dart';
import 'package:app/constants/constants.dart';
import 'package:app/enums.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/placeholders/placeholders.dart';
import 'package:app/ui/screens/info_sheet/info_sheet.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AlbumInfoPane extends StatelessWidget {
  final Song song;

  AlbumInfoPane({Key? key, required this.song}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final inOfflineMode =
        AppState.get('mode', AppMode.online) == AppMode.offline;

    if (inOfflineMode) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          vertical: AppDimensions.hPadding,
        ),
        child: Text(
          'No album information available.',
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }

    return FutureBuilder(
      future: Future.wait([
        context.read<AlbumProvider>().resolve(song.albumId),
        context.read<MediaInfoProvider>().fetchForAlbum(song.albumId),
      ]),
      builder: (context, AsyncSnapshot<dynamic> snapshot) {
        if (!snapshot.hasData || snapshot.hasError)
          return const MediaInfoPanePlaceholder();

        var album = snapshot.requireData[0] as Album;
        var info = snapshot.requireData[1] as AlbumInfo;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  AlbumArtistThumbnail.sm(entity: album),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      song.albumName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (info.information.isEmpty)
              const Padding(
                padding: const EdgeInsets.only(top: 16),
                child: const Text(
                  'No album information available.',
                  style: const TextStyle(color: Colors.white54),
                ),
              )
            else
              InfoHtml(content: info.information),
          ],
        );
      },
    );
  }
}

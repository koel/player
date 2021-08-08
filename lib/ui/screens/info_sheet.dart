import 'dart:ui';

import 'package:app/constants/dimensions.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/media_info_provider.dart';
import 'package:app/ui/widgets/album_thumbnail.dart';
import 'package:app/ui/widgets/artist_thumbnail.dart';
import 'package:app/ui/widgets/spinner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';

class InfoSheet extends StatefulWidget {
  final Song song;

  const InfoSheet({Key? key, required this.song}) : super(key: key);

  @override
  _InfoSheetState createState() => _InfoSheetState();
}

class _InfoSheetState extends State<InfoSheet> {
  late MediaInfoProvider infoProvider;
  late Future<MediaInfo> futureInfo;
  int _activeIndex = 0;

  final Map<int, Widget> tabs = const {
    0: const Text('Lyrics'),
    1: const Text('Artist'),
    2: const Text('Album'),
  };

  @override
  initState() {
    super.initState();
    infoProvider = context.read();
    futureInfo = infoProvider.fetch(song: widget.song);
  }

  Widget getActivePane({required MediaInfo info}) {
    switch (_activeIndex) {
      case 1:
        return ArtistInfoPane(song: widget.song, info: info.artistInfo);
      case 2:
        return AlbumInfoPane(song: widget.song, info: info.albumInfo);
      default:
        return LyricsPane(lyrics: info.lyrics);
    }
  }

  Widget build(BuildContext context) {
    return ClipRect(
      child: SafeArea(
        minimum: EdgeInsets.fromLTRB(
          AppDimensions.horizontalPadding,
          60,
          AppDimensions.horizontalPadding,
          MediaQuery.of(context).padding.bottom,
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40.0, sigmaY: 40.0),
          child: FutureBuilder<MediaInfo>(
            future: futureInfo,
            builder: (_, AsyncSnapshot<MediaInfo?> snapshot) {
              if (snapshot.hasError) {
                return const Text(
                  'Failed to fetch information. Please try again.',
                );
              }

              if (snapshot.connectionState != ConnectionState.done) {
                return const ContainerWithSpinner();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<int>(
                      children: tabs,
                      groupValue: _activeIndex,
                      onValueChanged: (value) {
                        setState(() => _activeIndex = value ?? 0);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: getActivePane(info: snapshot.data!),
                    ),
                  ),
                  Center(
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        CupertinoIcons.multiply_circle,
                        size: 32,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Wrap around the html content and apply a default style that is more readable
/// on a mobile device (e.g., line height).
class InfoHtml extends StatelessWidget {
  final String content;
  final Style? style;

  const InfoHtml({
    Key? key,
    required this.content,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Html(
      data: '<div>$content</div>',
      style: {
        'div': (style ?? Style()).copyWith(
          lineHeight: LineHeight.number(1.2),
        ),
      },
    );
  }
}

class LyricsPane extends StatelessWidget {
  final String? lyrics;

  LyricsPane({Key? key, this.lyrics}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return lyrics == null || lyrics == ''
        ? const Padding(
            padding: const EdgeInsets.only(top: 16),
            child: const Text(
              'No lyrics available.',
              style: const TextStyle(color: Colors.white54),
            ),
          )
        : InfoHtml(
            content: lyrics!,
            style: Style(fontSize: FontSize.larger),
          );
  }
}

class ArtistInfoPane extends StatelessWidget {
  final Song song;
  final ArtistInfo? info;

  ArtistInfoPane({Key? key, required this.song, this.info}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              ArtistThumbnail(artist: song.artist),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  song.artist.name,
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
        if (info == null || info!.biography == '')
          const Padding(
            padding: const EdgeInsets.only(top: 16),
            child: const Text(
              'No artist information available.',
              style: const TextStyle(color: Colors.white54),
            ),
          )
        else
          InfoHtml(content: info!.biography),
      ],
    );
  }
}

class AlbumInfoPane extends StatelessWidget {
  final Song song;
  final AlbumInfo? info;

  AlbumInfoPane({Key? key, required this.song, this.info}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              AlbumThumbnail(album: song.album),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  song.album.name,
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
        if (info == null || info!.information == '')
          const Padding(
            padding: const EdgeInsets.only(top: 16),
            child: const Text(
              'No album information available.',
              style: const TextStyle(color: Colors.white54),
            ),
          )
        else
          InfoHtml(content: info!.information),
      ],
    );
  }
}

Future<void> showInfoSheet(BuildContext context, {required Song song}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height,
          child: InfoSheet(song: song),
        ),
      );
    },
  );
}

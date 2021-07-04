import 'dart:ui';

import 'package:app/constants/dimens.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/media_info_provider.dart';
import 'package:app/ui/widgets/album_thumbnail.dart';
import 'package:app/ui/widgets/artist_thumbnail.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';

class InfoSheet extends StatefulWidget {
  final Song song;

  InfoSheet({Key? key, required this.song}) : super(key: key);

  @override
  _InfoSheetState createState() => _InfoSheetState();
}

class _InfoSheetState extends State<InfoSheet> {
  late MediaInfoProvider infoProvider;
  late Future<MediaInfo> futureInfo;
  int _activeIndex = 0;
  final Map<int, Widget> tabs = const {
    0: Text('Lyrics'),
    1: Text('Artist'),
    2: Text('Album'),
  };

  late Map<int, Widget> panes;

  @override
  initState() {
    super.initState();

    infoProvider = context.read();
    futureInfo = infoProvider.fetch(song: widget.song);
  }

  Widget html({required String content, Style? style}) {
    return Html(
      data: '<div>$content</div>',
      style: {
        'div': (style ?? Style()).copyWith(
          lineHeight: LineHeight.number(1.2),
        ),
      },
    );
  }

  Widget getActivePane({required MediaInfo info}) {
    switch (_activeIndex) {
      case 1:
        return artistPane(info: info.artistInfo);
      case 2:
        return albumPane(info: info.albumInfo);
      default:
        return lyricsPane(lyrics: info.lyrics);
    }
  }

  Widget lyricsPane({required String lyrics}) {
    return lyrics == ''
        ? html(content: 'No lyrics available.')
        : html(
            content: lyrics,
            style: Style(
              fontSize: FontSize.larger,
            ));
  }

  Widget artistPane({ArtistInfo? info}) {
    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              ArtistThumbnail(artist: widget.song.artist),
              SizedBox(width: 12),
              Text(
                widget.song.artist.name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        html(
          content: info == null || info.biography == ''
              ? 'No artist information available.'
              : info.biography,
        ),
      ],
    );
  }

  Widget albumPane({AlbumInfo? info}) {
    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              AlbumThumbnail(album: widget.song.album),
              SizedBox(width: 12),
              Flexible(
                child: Text(
                  widget.song.album.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        html(
          content: info == null || info.information == ''
              ? 'No album information available.'
              : info.information,
        ),
      ],
    );
  }

  Widget build(BuildContext context) {
    return ClipRect(
      child: SafeArea(
        minimum: EdgeInsets.symmetric(
          vertical: 60,
          horizontal: AppDimens.horizontalPadding,
        ),
        child: BackdropFilter(
          filter: new ImageFilter.blur(sigmaX: 40.0, sigmaY: 40.0),
          child: FutureBuilder<MediaInfo>(
            future: futureInfo,
            builder: (
              BuildContext context,
              AsyncSnapshot<MediaInfo?> snapshot,
            ) {
              if (snapshot.hasError) {
                return Text('Failed to fetch information. Please try again.');
              }

              if (snapshot.connectionState != ConnectionState.done) {
                return Text('Fetching information…');
              }

              return Column(
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
                  SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: getActivePane(info: snapshot.data!),
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

showInfoSheet(BuildContext context, {required Song song}) {
  showModalBottomSheet(
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

import 'dart:io';

import 'package:app/constants/constants.dart';
import 'package:app/models/models.dart';
import 'package:app/ui/screens/info_sheet/album_info_pane.dart';
import 'package:app/ui/screens/info_sheet/artist_info_pane.dart';
import 'package:app/ui/screens/info_sheet/lyrics_pane.dart';
import 'package:app/ui/widgets/widgets.dart' hide AppBar;
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class InfoSheet extends StatefulWidget {
  final Song song;
  final ScrollController scroller;

  const InfoSheet({Key? key, required this.song, required this.scroller})
      : super(key: key);

  @override
  _InfoSheetState createState() => _InfoSheetState();
}

class _InfoSheetState extends State<InfoSheet> {
  Widget build(BuildContext context) {
    Widget wrapTabPane(Widget pane) {
      return SingleChildScrollView(
        controller: widget.scroller,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.horizontalPadding,
            vertical: 8.0,
          ),
          child: pane,
        ),
      );
    }

    return FrostedGlassBackground(
      sigma: 40.0,
      child: SafeArea(
        child: DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              bottom: const TabBar(
                indicatorColor: AppColors.highlight,
                tabs: [
                  Tab(text: 'Lyrics'),
                  Tab(text: 'Artist'),
                  Tab(text: 'Album'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                wrapTabPane(LyricsPane(song: widget.song)),
                wrapTabPane(ArtistInfoPane(song: widget.song)),
                wrapTabPane(AlbumInfoPane(song: widget.song)),
              ],
            ),
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

  const InfoHtml({Key? key, required this.content, this.style})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Html(
      data: '<div>$content</div>',
      style: {
        'body': Style().copyWith(
          padding: EdgeInsets.zero,
          margin: EdgeInsets.zero,
        ),
        'div': (style ?? Style()).copyWith(
          fontSize: FontSize.large,
          lineHeight: LineHeight.number(1.4),
        ),
      },
    );
  }
}

Future<void> showInfoSheet(BuildContext context, {required Song song}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return DraggableScrollableSheet(
        initialChildSize: 1,
        minChildSize: .5,
        snap: true,
        snapAnimationDuration: const Duration(milliseconds: 100),
        builder: (BuildContext context, ScrollController scrollController) {
          return ClipSmoothRect(
            radius: Platform.isIOS ? SmoothBorderRadius(
              cornerRadius: 32,
              cornerSmoothing: .5,
            ):  SmoothBorderRadius.zero,
            child: InfoSheet(song: song, scroller: scrollController),
          );
        },
      );
    },
  );
}

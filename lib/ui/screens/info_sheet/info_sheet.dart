import 'dart:io';

import 'package:app/constants/constants.dart';
import 'package:app/models/models.dart';
import 'package:app/ui/screens/info_sheet/album_info_pane.dart';
import 'package:app/ui/screens/info_sheet/artist_info_pane.dart';
import 'package:app/ui/screens/info_sheet/lyrics_pane.dart';
import 'package:app/ui/widgets/widgets.dart' hide AppBar;
import 'package:fading_edge_scrollview/fading_edge_scrollview.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoSheet extends StatefulWidget {
  final Playable playable;
  final ScrollController scroller;

  const InfoSheet({Key? key, required this.playable, required this.scroller})
      : super(key: key);

  @override
  _InfoSheetState createState() => _InfoSheetState();
}

class _InfoSheetState extends State<InfoSheet> {
  Widget build(BuildContext context) {
    Widget wrapTabPane(Widget pane) {
      return FadingEdgeScrollView.fromSingleChildScrollView(
        gradientFractionOnStart: .3,
        gradientFractionOnEnd: .3,
        child: SingleChildScrollView(
          controller: widget.scroller,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.hPadding,
              vertical: 8.0,
            ),
            child: pane,
          ),
        ),
      );
    }

    return FrostedGlassBackground(
      sigma: 40.0,
      child: SafeArea(
        child: DefaultTabController(
          length: widget.playable is Song ? 3 : 1,
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              bottom: TabBar(
                tabs: [
                  if (widget.playable is Song) Tab(text: 'Lyrics'),
                  if (widget.playable is Song) Tab(text: 'Artist'),
                  if (widget.playable is Song) Tab(text: 'Album'),
                  if (widget.playable is Episode) Tab(text: 'Description'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                if (widget.playable is Song)
                  wrapTabPane(LyricsPane(song: widget.playable as Song)),
                if (widget.playable is Song)
                  wrapTabPane(ArtistInfoPane(song: widget.playable as Song)),
                if (widget.playable is Song)
                  wrapTabPane(AlbumInfoPane(song: widget.playable as Song)),
                if (widget.playable is Episode)
                  wrapTabPane(
                    InfoHtml(content: (widget.playable as Episode).description),
                  ),
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
    return SelectionArea(
      child: Html(
          data: '<div>$content</div>',
          style: {
            'body': Style().copyWith(
              padding: HtmlPaddings.zero,
              margin: Margins.zero,
            ),
            'a': Style().copyWith(
              textDecoration: TextDecoration.none,
              color: Colors.blueAccent,
            ),
            'div': (style ?? Style()).copyWith(
              fontSize: FontSize.large,
              lineHeight: LineHeight.number(1.4),
            ),
          },
          onLinkTap: (url, _, __) async {
            try {
              await launchUrl(Uri.parse(url!));
            } catch (e) {
              print('Error launching URL: $e');
            }
          }),
    );
  }
}

Future<void> showInfoSheet(BuildContext context, {required Playable playable}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return DraggableScrollableSheet(
        initialChildSize: 1,
        minChildSize: .5,
        snap: true,
        snapAnimationDuration: const Duration(milliseconds: 100),
        builder: (BuildContext context, ScrollController scrollController) {
          return ClipSmoothRect(
            radius: Platform.isIOS
                ? SmoothBorderRadius(
                    cornerRadius: 32,
                    cornerSmoothing: .5,
                  )
                : SmoothBorderRadius.zero,
            child: InfoSheet(playable: playable, scroller: scrollController),
          );
        },
      );
    },
  );
}

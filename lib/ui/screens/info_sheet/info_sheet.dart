import 'package:app/app_state.dart';
import 'package:app/constants/constants.dart';
import 'package:app/enums.dart';
import 'package:app/models/models.dart';
import 'package:app/ui/screens/info_sheet/album_info_pane.dart';
import 'package:app/ui/screens/info_sheet/artist_info_pane.dart';
import 'package:app/ui/screens/info_sheet/lyrics_pane.dart';
import 'package:app/ui/widgets/frosted_glass_background.dart';
import 'package:flutter/cupertino.dart';
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
  var _activeIndex = 0;

  Widget getActivePane() {
    switch (_activeIndex) {
      case 1:
        return ArtistInfoPane(song: widget.song);
      case 2:
        return AlbumInfoPane(song: widget.song);
      default:
        return LyricsPane(song: widget.song);
    }
  }

  Widget build(BuildContext context) {
    final inOfflineMode =
        AppState.get('mode', AppMode.online) == AppMode.offline;
    final textStyle =
        inOfflineMode ? const TextStyle(color: Colors.white30) : null;

    final tabs = <int, Widget>{
      0: const Text('Lyrics'),
      1: Text('Artist', style: textStyle),
      2: Text('Album', style: textStyle),
    };

    return FrostedGlassBackground(
      sigma: 40.0,
      child: SafeArea(
        minimum: EdgeInsets.fromLTRB(
          AppDimensions.horizontalPadding,
          60,
          AppDimensions.horizontalPadding,
          MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              child: CupertinoSlidingSegmentedControl<int>(
                thumbColor: AppColors.highlight,
                children: tabs,
                groupValue: _activeIndex,
                onValueChanged: (value) {
                  if (inOfflineMode) return;
                  setState(() => _activeIndex = value ?? 0);
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                controller: widget.scroller,
                child: getActivePane(),
              ),
            ),
          ],
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
          return InfoSheet(song: song, scroller: scrollController);
        },
      );
    },
  );
}

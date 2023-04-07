import 'package:app/constants/constants.dart';
import 'package:app/models/models.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A simple song list to display a small amount of song rows.
/// Not meant to be used for a great number for rows, in such a case
/// use SliverList or something similar instead.
class SimpleSongList extends StatelessWidget {
  final Iterable<Song> songs;
  final String? headingText;
  final bool bordered;
  final void Function()? onHeaderTap;

  const SimpleSongList({
    Key? key,
    required this.songs,
    this.headingText,
    this.bordered = false,
    this.onHeaderTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final headingText = this.headingText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (headingText != null)
          GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onHeaderTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.hPadding,
                ),
                child: Heading5(text: headingText),
              )),
        ...songs.map(
          (song) => SongRow(
            song: song,
            bordered: bordered,
          ),
        )
      ],
    );
  }
}

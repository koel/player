import 'package:app/constants/constants.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum SongListContext {
  queue,
  allSongs,
  album,
  artist,
  playlist,
  favorites,
  other,
  downloads,
}

class SongListHeader extends StatefulWidget {
  final List<Song> songs;
  final Function(String keywords)? onSearchQueryChanged;
  final Function()? onPlayPressed;
  final Function()? onShufflePressed;
  final Function()? onSearchExpanded;
  final Function()? onSearchCollapsed;
  final Widget? playIcon;
  final Widget? shuffleIcon;

  const SongListHeader({
    Key? key,
    required this.songs,
    this.onSearchQueryChanged,
    this.onSearchExpanded,
    this.onSearchCollapsed,
    this.onPlayPressed,
    this.onShufflePressed,
    this.playIcon,
    this.shuffleIcon,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SongListHeaderState();
}

class _SongListHeaderState extends State<SongListHeader> {
  bool _displayingSearch = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      if (widget.onSearchQueryChanged != null) {
        widget.onSearchQueryChanged!(_searchController.text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var playIcon = widget.playIcon ?? const Icon(CupertinoIcons.play_fill);
    var shuffleIcon = widget.shuffleIcon ?? const Icon(CupertinoIcons.shuffle);

    final AudioProvider audio = context.read();

    final double verticalPadding = _displayingSearch ? 10 : 8;

    return Container(
      padding: EdgeInsets.fromLTRB(
        _displayingSearch ? 16 : 8,
        verticalPadding,
        _displayingSearch ? 0 : 8,
        verticalPadding,
      ),
      child: Row(children: <Widget>[
        if (!_displayingSearch) ...<Widget>[
          IconButton(
            onPressed: () {
              setState(() => _displayingSearch = true);
              widget.onSearchExpanded?.call();
            },
            icon: const Icon(CupertinoIcons.search),
          ),
          const Spacer(),
        ] else ...[
          Expanded(
            child: CupertinoSearchTextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              autofocus: true,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: AppDimensions.inputBorderRadius,
              ),
            ),
          ),
          CupertinoButton(
            onPressed: () {
              setState(() => _displayingSearch = false);
              _searchController.clear();
              widget.onSearchCollapsed?.call();
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.red),
            ),
          ),
        ],
        if (!_displayingSearch) ...<Widget>[
          IconButton(
            onPressed: () async {
              if (widget.onPlayPressed != null) {
                widget.onPlayPressed!();
                return;
              }
              await audio.replaceQueue(widget.songs);
            },
            icon: SizedBox(
              height: 24,
              width: 24,
              child: playIcon,
            ),
          ),
          const SizedBox(width: 6),
          ElevatedButton(
            onPressed: () async {
              if (widget.onShufflePressed != null) {
                widget.onShufflePressed!();
                return;
              }
              await audio.replaceQueue(widget.songs, shuffle: true);
            },
            child: SizedBox(
              height: 24,
              width: 24,
              child: shuffleIcon,
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              elevation: 0,
              shape: CircleBorder(),
              backgroundColor: AppColors.highlight,
            ),
          ),
        ],
      ]),
    );
  }
}

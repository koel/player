import 'package:app/constants/constants.dart';
import 'package:app/main.dart';
import 'package:app/models/models.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum PlayableListContext {
  queue,
  allSongs,
  album,
  artist,
  playlist,
  favorites,
  other,
  downloads,
  recentlyPlayed,
  podcast
}

class PlayableListHeader extends StatefulWidget {
  final List<Playable> playables;
  final Function(String keywords)? onSearchQueryChanged;
  final Function()? onPlayPressed;
  final Function()? onShufflePressed;
  final Function()? onSearchExpanded;
  final Function()? onSearchCollapsed;
  final Widget? playIcon;
  final Widget? shuffleIcon;

  const PlayableListHeader({
    Key? key,
    required this.playables,
    this.onSearchQueryChanged,
    this.onSearchExpanded,
    this.onSearchCollapsed,
    this.onPlayPressed,
    this.onShufflePressed,
    this.playIcon,
    this.shuffleIcon,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PlayableListHeaderState();
}

class _PlayableListHeaderState extends State<PlayableListHeader> {
  var _displayingSearch = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      widget.onSearchQueryChanged?.call(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final playIcon = widget.playIcon ?? const Icon(CupertinoIcons.play_fill);
    final shuffleIcon =
        widget.shuffleIcon ?? const Icon(CupertinoIcons.shuffle);

    final onPlayPressed = widget.onPlayPressed ??
        () => audioHandler.replaceQueue(widget.playables);

    final onShufflePressed = widget.onShufflePressed ??
        () => audioHandler.replaceQueue(widget.playables, shuffle: true);

    final Widget buttonsHeader = Row(
      children: <Widget>[
        IconButton(
          onPressed: () {
            setState(() => _displayingSearch = true);
            widget.onSearchExpanded?.call();
          },
          icon: const Icon(CupertinoIcons.search),
        ),
        const Spacer(),
        IconButton(
          onPressed: onPlayPressed,
          icon: SizedBox.square(dimension: 24, child: playIcon),
        ),
        const SizedBox(width: 6),
        ElevatedButton(
          onPressed: onShufflePressed,
          child: SizedBox.square(dimension: 24, child: shuffleIcon),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            elevation: 0,
            shape: CircleBorder(),
            backgroundColor: AppColors.highlight,
          ),
        ),
      ],
    );

    final Widget searchHeader = Row(
      children: <Widget>[
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
            style: TextStyle(color: AppColors.white.withOpacity(.7)),
          ),
        ),
      ],
    );

    final double verticalPadding = _displayingSearch ? 10 : 8;

    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      child: Container(
        key: ValueKey<bool>(_displayingSearch),
        padding: EdgeInsets.fromLTRB(
          _displayingSearch ? 16 : 8,
          verticalPadding,
          _displayingSearch ? 0 : 8,
          verticalPadding,
        ),
        child: _displayingSearch ? searchHeader : buttonsHeader,
      ),
    );
  }
}

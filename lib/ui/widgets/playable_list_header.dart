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
  podcast,
  genre
}

class PlayableListHeader extends StatefulWidget {
  final List<Playable> playables;
  final ScrollController? scrollController;
  final Function(String keywords)? onSearchQueryChanged;
  final Function()? onPlayPressed;
  final Function()? onShufflePressed;

  const PlayableListHeader({
    Key? key,
    required this.playables,
    this.scrollController,
    this.onSearchQueryChanged,
    this.onPlayPressed,
    this.onShufflePressed,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PlayableListHeaderState();
}

class _PlayableListHeaderState extends State<PlayableListHeader> {
  final _searchController = TextEditingController();
  var _searching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      widget.onSearchQueryChanged?.call(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _searching = true);
  }

  void _closeSearch() {
    _searchController.clear();
    setState(() => _searching = false);
  }

  @override
  Widget build(BuildContext context) {
    final onPlayPressed = widget.onPlayPressed ??
        () => audioHandler.replaceQueue(widget.playables);

    final onShufflePressed = widget.onShufflePressed ??
        () => audioHandler.replaceQueue(widget.playables, shuffle: true);

    const rowHeight = 48.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: rowHeight,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _searching
              ? Row(
                  key: const ValueKey('search'),
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: rowHeight,
                        child: CupertinoSearchTextField(
                          controller: _searchController,
                          autofocus: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.only(left: 12),
                      onPressed: _closeSearch,
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                )
              : Row(
                  key: const ValueKey('buttons'),
                  children: [
                    SizedBox(
                      height: rowHeight,
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(100),
                        minSize: 0,
                        onPressed: _openSearch,
                        child: const Icon(CupertinoIcons.search,
                            size: 20, color: Colors.white70),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: rowHeight,
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(100),
                          onPressed: onPlayPressed,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.play_fill,
                                  size: 18, color: AppColors.highlight),
                              const SizedBox(width: 8),
                              Text('Play',
                                  style:
                                      TextStyle(color: AppColors.highlight)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: rowHeight,
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(100),
                          onPressed: onShufflePressed,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.shuffle,
                                  size: 18, color: AppColors.highlight),
                              const SizedBox(width: 8),
                              Text('Shuffle',
                                  style:
                                      TextStyle(color: AppColors.highlight)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

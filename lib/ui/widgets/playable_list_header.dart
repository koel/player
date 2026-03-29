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

class _PlayableListHeaderState extends State<PlayableListHeader>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  late final AnimationController _animController;
  late final Animation<double> _searchWidth;
  var _searching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      widget.onSearchQueryChanged?.call(_searchController.text);
    });
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _searchWidth = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _searching = true);
    _animController.forward();
    _focusNode.requestFocus();
  }

  void _closeSearch() {
    _searchController.clear();
    _focusNode.unfocus();
    _animController.reverse().then((_) {
      if (mounted) setState(() => _searching = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final onPlayPressed = widget.onPlayPressed ??
        () => audioHandler.replaceQueue(widget.playables);

    final onShufflePressed = widget.onShufflePressed ??
        () => audioHandler.replaceQueue(widget.playables, shuffle: true);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 48,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            const searchButtonWidth = 48.0;
            const gap = 10.0;

            return AnimatedBuilder(
              animation: _searchWidth,
              builder: (context, _) {
                final t = _searchWidth.value;
                final expandedWidth =
                    searchButtonWidth + (totalWidth - searchButtonWidth) * t;

                return ClipRect(
                  child: Row(
                  children: [
                    // Search button / expanded search pill
                    SizedBox(
                      width: expandedWidth,
                      height: 48,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: t < 0.3
                            ? Center(
                                child: GestureDetector(
                                  onTap: _openSearch,
                                  behavior: HitTestBehavior.opaque,
                                  child: const SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: Icon(CupertinoIcons.search,
                                        size: 20, color: Colors.white70),
                                  ),
                                ),
                              )
                            : Row(
                                children: [
                                  const SizedBox(width: 14),
                                  const Icon(CupertinoIcons.search,
                                      size: 18, color: Colors.white38),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      focusNode: _focusNode,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 16),
                                      cursorColor: AppColors.highlight,
                                      decoration: const InputDecoration(
                                        hintText: 'Search',
                                        hintStyle: TextStyle(
                                            color: Colors.white30,
                                            fontSize: 16),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        filled: false,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _closeSearch,
                                    child: const Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 12),
                                      child: Icon(CupertinoIcons.xmark_circle_fill,
                                          size: 18, color: Colors.white38),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    // Play and Shuffle buttons — fade and shrink as search expands
                    if (t < 0.3) ...[
                      SizedBox(width: gap * (1 - t)),
                      Expanded(
                        child: Opacity(
                          opacity: (1 - t * 4).clamp(0.0, 1.0),
                          child: SizedBox(
                            height: 48,
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(100),
                              onPressed: _searching ? null : onPlayPressed,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(CupertinoIcons.play_fill,
                                      size: 18, color: AppColors.highlight),
                                  const SizedBox(width: 8),
                                  Text('Play',
                                      style: TextStyle(
                                          color: AppColors.highlight)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: gap * (1 - t)),
                      Expanded(
                        child: Opacity(
                          opacity: (1 - t * 4).clamp(0.0, 1.0),
                          child: SizedBox(
                            height: 48,
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(100),
                              onPressed: _searching ? null : onShufflePressed,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(CupertinoIcons.shuffle,
                                      size: 18, color: AppColors.highlight),
                                  const SizedBox(width: 8),
                                  Text('Shuffle',
                                      style: TextStyle(
                                          color: AppColors.highlight)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ));
              },
            );
          },
        ),
      ),
    );
  }
}

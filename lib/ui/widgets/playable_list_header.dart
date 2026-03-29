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
  var _showSearch = false;
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      widget.onSearchQueryChanged?.call(_searchController.text);
    });

    widget.scrollController?.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant PlayableListHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_onScroll);
      widget.scrollController?.addListener(_onScroll);
    }
  }

  void _onScroll() {
    final controller = widget.scrollController;
    if (controller == null || !controller.hasClients) return;

    final offset = controller.offset;
    final delta = offset - _lastScrollOffset;
    _lastScrollOffset = offset;

    if (delta > 2 && !_showSearch && offset > 50) {
      setState(() => _showSearch = true);
    } else if (delta < -2 && _showSearch && _searchController.text.isEmpty) {
      setState(() => _showSearch = false);
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onPlayPressed = widget.onPlayPressed ??
        () => audioHandler.replaceQueue(widget.playables);

    final onShufflePressed = widget.onShufflePressed ??
        () => audioHandler.replaceQueue(widget.playables, shuffle: true);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _showSearch
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CupertinoSearchTextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                  onPressed: onPlayPressed,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.play_fill,
                          size: 18, color: AppColors.highlight),
                      const SizedBox(width: 8),
                      Text('Play',
                          style: TextStyle(color: AppColors.highlight)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                  onPressed: onShufflePressed,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.shuffle,
                          size: 18, color: AppColors.highlight),
                      const SizedBox(width: 8),
                      Text('Shuffle',
                          style: TextStyle(color: AppColors.highlight)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

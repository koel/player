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
}

class ButtonConfig {
  final String label;
  final Widget icon;
  final void Function()? onPressed;

  const ButtonConfig({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
}

class SongListButtons extends StatefulWidget {
  final List<Song> songs;
  final List<ButtonConfig> buttons;
  final Function(String keywords)? onSearchChanged;
  final Function()? onPlayPressed;
  final Function()? onShufflePressed;

  const SongListButtons({
    Key? key,
    required this.songs,
    this.buttons = const [],
    this.onSearchChanged,
    this.onPlayPressed,
    this.onShufflePressed,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SongListButtonsState();
}

class _SongListButtonsState extends State<SongListButtons> {
  bool _displayingSearch = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      if (widget.onSearchChanged != null) {
        widget.onSearchChanged!(_searchController.text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: () => setState(() => _displayingSearch = true),
            icon: const Icon(CupertinoIcons.search),
          ),
          const Spacer(),
        ] else ...[
          Expanded(
            child: CupertinoSearchTextField(
              controller: _searchController,
              style: TextStyle(color: Colors.white),
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
            icon: const Icon(CupertinoIcons.play_fill),
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
            child: const Icon(CupertinoIcons.shuffle),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              elevation: 0,
              shape: CircleBorder(),
              backgroundColor: AppColors.white.withOpacity(0.2),
            ),
          ),
        ],
      ]),
    );
  }
}

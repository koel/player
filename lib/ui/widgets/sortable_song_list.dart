import 'package:app/models/models.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum SortField {
  trackNumber,
  artist,
  album,
  title,
  recentlyAdded,
}

List<Song> sortSongs(List<Song> songs, {required SortField orderBy}) {
  switch (orderBy) {
    case SortField.title:
      return songs..sort((a, b) => a.title.compareTo(b.title));
    case SortField.artist:
      return songs..sort((a, b) => a.artistName.compareTo(b.artistName));
    case SortField.album:
      return songs
        ..sort((a, b) => '${a.albumName}${a.albumId}${a.track}'
            .compareTo('${b.albumName}${b.albumId}${b.track}'));
    case SortField.recentlyAdded:
      return songs..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    case SortField.trackNumber:
      return songs..sort((a, b) => a.track.compareTo(b.track));
    default:
      throw Exception('Invalid order.');
  }
}

class SortButton extends StatelessWidget {
  final Map<SortField, String> options;
  final void Function(SortField order)? onActionSheetActionPressed;
  final SortField currentSortField;

  const SortButton({
    Key? key,
    required this.options,
    required this.currentSortField,
    this.onActionSheetActionPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SortField _currentOrder = currentSortField;

    return IconButton(
      onPressed: () {
        showCupertinoModalPopup(
          context: context,
          builder: (BuildContext context) => CupertinoActionSheet(
            title: const Text('Sort by'),
            actions: options.entries
                .map(
                  (entry) => CupertinoActionSheetAction(
                    onPressed: () {
                      _currentOrder = entry.key;
                      onActionSheetActionPressed?.call(entry.key);
                      Navigator.pop(context);
                    },
                    child: Text(
                      (entry.key == _currentOrder ? '✓ ' : ' ') + entry.value,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
      icon: Icon(CupertinoIcons.sort_down),
    );
  }
}

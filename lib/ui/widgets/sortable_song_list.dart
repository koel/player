import 'package:app/models/song.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum OrderBy {
  trackNumber,
  artist,
  album,
  title,
  recentlyAdded,
}

List<Song> sortSongs(List<Song> songs, {required OrderBy orderBy}) {
  switch (orderBy) {
    case OrderBy.title:
      return songs..sort((a, b) => a.title.compareTo(b.title));
    case OrderBy.artist:
      return songs..sort((a, b) => a.artist.name.compareTo(b.artist.name));
    case OrderBy.album:
      return songs
        ..sort((a, b) => '${a.album.name}${a.albumId}${a.track}'
            .compareTo('${b.album.name}${b.albumId}${b.track}'));
    case OrderBy.recentlyAdded:
      return songs..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    case OrderBy.trackNumber:
      return songs..sort((a, b) => a.track.compareTo(b.track));
    default:
      throw Exception('Invalid order.');
  }
}

class SortButton extends StatelessWidget {
  final Map<OrderBy, String> options;
  final void Function(OrderBy order)? onActionSheetActionPressed;
  final OrderBy currentOrder;

  const SortButton({
    Key? key,
    required this.options,
    required this.currentOrder,
    this.onActionSheetActionPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    OrderBy _currentOrder = currentOrder;

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

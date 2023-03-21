import 'package:app/enums.dart';
import 'package:app/models/models.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const sortFields = {
  'track': 'Track number',
  'disc': 'Disc number',
  'title': 'Title',
  'album_name': 'Album',
  'artist_name': 'Artist',
  'created_at': 'Recently added',
  'length': 'Length',
};

List<Song> sortSongs(List<Song> songs, {required SongSortConfig config}) {
  switch (config.field) {
    case 'title':
      return songs
        ..sort(
          (a, b) => config.order == SortOrder.asc
              ? a.title.compareTo(b.title)
              : b.title.compareTo(a.title),
        );
    case 'artist_name':
      return songs
        ..sort(
          (a, b) => config.order == SortOrder.asc
              ? '${a.artistName}${a.albumName}${a.track}'
                  .compareTo('${b.artistName}${b.albumName}${b.track}')
              : '${b.artistName}${b.albumName}${b.title}'
                  .compareTo('${a.artistName}${a.albumName}${a.track}'),
        );
    case 'album_name':
      return songs
        ..sort(
          (a, b) => config.order == SortOrder.asc
              ? '${a.albumName}${a.albumId}${a.track}'
                  .compareTo('${b.albumName}${b.albumId}${b.track}')
              : '${b.albumName}${b.albumId}${b.track}'
                  .compareTo('${a.albumName}${a.albumId}${a.track}'),
        );
    case 'created_at':
      return songs
        ..sort(
          (a, b) => config.order == SortOrder.asc
              ? a.createdAt.compareTo(b.createdAt)
              : b.createdAt.compareTo(a.createdAt),
        );
    case 'track':
      // @todo add sort by disc
      return songs
        ..sort(
          (a, b) => config.order == SortOrder.asc
              ? a.track.compareTo(b.track)
              : b.track.compareTo(a.track),
        );
    // @todo sort by disc and length
    default:
      throw Exception('Invalid sort field.');
  }
}

class SortButton extends StatelessWidget {
  final List<String> fields;
  final void Function(SongSortConfig sortConfig)? onActionSheetActionPressed;
  final String currentField;
  final SortOrder currentOrder;

  SortButton({
    Key? key,
    required this.fields,
    required this.currentField,
    required this.currentOrder,
    this.onActionSheetActionPressed,
  }) : super(key: key) {
    assert(fields.isNotEmpty);
    assert(fields.every((field) => sortFields.containsKey(field)));
    assert(fields.contains(currentField));
  }

  @override
  Widget build(BuildContext context) {
    String _currentField = currentField;
    SortOrder _order = currentOrder;

    return IconButton(
      onPressed: () {
        showCupertinoModalPopup(
          context: context,
          builder: (BuildContext context) => CupertinoActionSheet(
            title: const Text('Sort by'),
            actions: fields
                .map(
                  (field) => CupertinoActionSheetAction(
                    onPressed: () {
                      if (field == _currentField) {
                        _order = _order == SortOrder.asc
                            ? SortOrder.desc
                            : SortOrder.asc;
                      } else {
                        _order = SortOrder.asc;
                      }

                      _currentField = field;
                      onActionSheetActionPressed?.call(
                        SongSortConfig(
                          field: field,
                          order: _order,
                        ),
                      );
                      Navigator.pop(context);
                    },
                    child: Text(
                      (field == _currentField
                              ? (_order == SortOrder.asc ? '↓ ' : '↑ ')
                              : ' ') +
                          sortFields[field]!,
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

class SongSortConfig {
  String field;
  SortOrder order;

  SongSortConfig({
    required this.field,
    required this.order,
  });
}

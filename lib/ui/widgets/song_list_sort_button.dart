import 'package:app/enums.dart';
import 'package:app/values/values.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SortButton extends StatelessWidget {
  final List<String> fields;
  final void Function(SongSortConfig sortConfig)? onActionSheetActionPressed;
  final String currentField;
  final SortOrder currentOrder;

  static const sortFields = {
    'track': 'Track number',
    'disc': 'Disc number',
    'title': 'Title',
    'album_name': 'Album',
    'artist_name': 'Artist',
    'created_at': 'Recently added',
    'length': 'Length',
  };

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

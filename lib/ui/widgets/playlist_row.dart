import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/screens/screens.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class PlaylistRow extends StatefulWidget {
  final Playlist playlist;

  final void Function()? onTap;

  const PlaylistRow({Key? key, required this.playlist, this.onTap})
      : super(key: key);

  _PlaylistRowState createState() => _PlaylistRowState();
}

class _PlaylistRowState extends State<PlaylistRow> with StreamSubscriber {
  late final PlaylistProvider playlistProvider;
  late Playlist _playlist;

  Offset? _lastTapPosition;

  @override
  initState() {
    super.initState();
    playlistProvider = context.read();
    setState(() => _playlist = widget.playlist);
  }

  void _defaultOnTap() => gotoDetailsScreen(context, playlist: _playlist);

  Future<void> _onLongPress() async {
    final canEdit = _playlist.canEdit;
    final canDelete = _playlist.canDelete;
    if (!canEdit && !canDelete) return;

    HapticFeedback.mediumImpact();

    final selected = await showFrostedContextMenu<String>(
      context: context,
      position: _lastTapPosition ?? Offset.zero,
      items: [
        if (canEdit)
          const FrostedMenuItem(
            value: 'edit',
            icon: CupertinoIcons.pencil,
            label: 'Edit',
          ),
        if (canDelete)
          const FrostedMenuItem(
            value: 'delete',
            icon: CupertinoIcons.trash,
            label: 'Delete',
            destructive: true,
          ),
      ],
    );

    if (!mounted) return;

    switch (selected) {
      case 'edit':
        await showEditPlaylistDialog(context, playlist: _playlist);
        if (mounted) setState(() {});
        break;
      case 'delete':
        await _confirmAndDelete();
        break;
    }
  }

  Future<void> _confirmAndDelete() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Delete playlist?'),
        content: Text('Delete "${_playlist.name}"? This cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await playlistProvider.remove(_playlist);
    if (mounted) showOverlay(context, caption: 'Playlist deleted');
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap ?? _defaultOnTap,
      onTapDown: (details) => _lastTapPosition = details.globalPosition,
      onLongPress: _onLongPress,
      child: ListTile(
        shape: Border(bottom: Divider.createBorderSide(context)),
        leading: PlaylistThumbnail(playlist: _playlist),
        title: Text(_playlist.name, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          _playlist.isSmart ? 'Smart playlist' : 'Standard playlist',
        ),
      ),
    );
  }
}

class PlaylistThumbnail extends StatelessWidget {
  final Playlist playlist;

  const PlaylistThumbnail({Key? key, required this.playlist}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Icon(
      CupertinoIcons.music_note_list,
      color: Colors.white54,
    );
  }
}

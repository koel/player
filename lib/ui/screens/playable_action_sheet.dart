import 'package:app/app_state.dart';
import 'package:app/enums.dart';
import 'package:app/main.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/router.dart';
import 'package:app/ui/screens/add_to_playlist.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

class PlayableActionSheet extends StatefulWidget {
  final Playable playable;

  const PlayableActionSheet({Key? key, required this.playable})
      : super(key: key);

  @override
  _PlayableActionSheetState createState() => _PlayableActionSheetState();
}

class _PlayableActionSheetState extends State<PlayableActionSheet> {
  var _queued = false;

  initState() {
    super.initState();

    audioHandler.queued(widget.playable).then((queued) {
      setState(() => _queued = queued);
    });
  }

  @override
  Widget build(BuildContext context) {
    final playable = widget.playable;
    final favoriteProvider = context.read<FavoriteProvider>();
    final isCurrent = audioHandler.mediaItem.value != null &&
        audioHandler.mediaItem.value!.id == playable.id;
    final inOfflineMode =
        AppState.get('mode', AppMode.online) == AppMode.offline;

    late final String subtitle;

    if (playable is Song) {
      subtitle = '${playable.artistName} • ${playable.albumName}';
    } else if (playable is Episode) {
      subtitle = playable.podcastTitle;
    } else {
      subtitle = '';
    }

    return FrostedGlassBackground(
      sigma: 40.0,
      child: Container(
        padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const SizedBox.shrink(), // to properly align the thumbnail area
            Column(
              children: [
                PlayableThumbnail.lg(playable: playable),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    playable.title,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ),
            ListView(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: <Widget>[
                if (!isCurrent)
                  PlayableActionButton(
                    text: 'Play Next',
                    icon: const Icon(
                      CupertinoIcons.arrow_right_circle_fill,
                      color: Colors.white30,
                    ),
                    onTap: () async {
                      await audioHandler.queueAfterCurrent(playable);
                      showOverlay(
                        context,
                        icon: CupertinoIcons.arrow_right_circle_fill,
                        caption: 'Queued',
                        message: 'To be played next.',
                      );
                    },
                  ),
                if (!isCurrent)
                  PlayableActionButton(
                    text: 'Play Last',
                    icon: const Icon(
                      CupertinoIcons.arrow_down_right_circle_fill,
                      color: Colors.white30,
                    ),
                    onTap: () async {
                      await audioHandler.queueToBottom(playable);
                      showOverlay(
                        context,
                        icon: CupertinoIcons.arrow_down_right_circle_fill,
                        caption: 'Queued',
                        message: 'Queued to bottom.',
                      );
                    },
                  ),
                if (_queued)
                  PlayableActionButton(
                    text: 'Remove from Queue',
                    icon: const Icon(
                      CupertinoIcons.text_badge_minus,
                      color: Colors.white30,
                    ),
                    onTap: () async {
                      await audioHandler.removeFromQueue(playable);
                      showOverlay(
                        context,
                        icon: CupertinoIcons.text_badge_minus,
                        caption: 'Removed',
                        message: 'Removed from queue.',
                      );
                    },
                  ),
                PlayableActionButton(
                  enabled: !inOfflineMode,
                  text: playable.liked
                      ? 'Remove as Favorite'
                      : 'Mark as Favorite',
                  icon: Icon(
                    playable.liked
                        ? CupertinoIcons.heart_fill
                        : CupertinoIcons.heart,
                    color: Colors.white30,
                  ),
                  onTap: () {
                    showOverlay(
                      context,
                      caption: playable.liked ? 'Unliked' : 'Liked',
                      message: playable.liked
                          ? 'Removed from Favorites.'
                          : 'Added to Favorites.',
                      icon: playable.liked
                          ? CupertinoIcons.heart_slash
                          : CupertinoIcons.heart_fill,
                    );
                    favoriteProvider.toggleOne(playable: playable);
                  },
                ),
                const Divider(indent: 16, endIndent: 16),
                if (playable is Song)
                  PlayableActionButton(
                    enabled: !inOfflineMode,
                    text: 'Go to Album',
                    icon: const Icon(
                      CupertinoIcons.music_albums_fill,
                      color: Colors.white30,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      AppRouter().gotoAlbumDetailsScreen(
                        context,
                        albumId: playable.albumId,
                      );
                    },
                    hideSheetOnTap: false,
                  ),
                if (playable is Episode)
                  PlayableActionButton(
                    enabled: !inOfflineMode,
                    text: 'Go to Podcast',
                    icon: const Icon(
                      LucideIcons.podcast,
                      color: Colors.white30,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      AppRouter().gotoPodcastDetailsScreen(
                        context,
                        podcastId: playable.podcastId,
                      );
                    },
                    hideSheetOnTap: false,
                  ),
                if (playable is Song)
                  PlayableActionButton(
                    enabled: !inOfflineMode,
                    text: 'Go to Artist',
                    icon: const Icon(
                      CupertinoIcons.music_mic,
                      color: Colors.white30,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      AppRouter().gotoArtistDetailsScreen(
                        context,
                        artistId: playable.artistId,
                      );
                    },
                    hideSheetOnTap: false,
                  ),
                const Divider(indent: 16, endIndent: 16),
                PlayableActionButton(
                  enabled: !inOfflineMode,
                  text: 'Add to a Playlist…',
                  icon: const Icon(
                    CupertinoIcons.text_badge_plus,
                    color: Colors.white30,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    gotoAddToPlaylistScreen(context, playable: playable);
                  },
                  hideSheetOnTap: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PlayableActionButton extends StatelessWidget {
  final String text;
  final Icon icon;
  final Function onTap;
  final bool hideSheetOnTap;
  final bool enabled;

  const PlayableActionButton({
    Key? key,
    required this.text,
    required this.icon,
    required this.onTap,
    this.hideSheetOnTap = true,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon,
      minLeadingWidth: 16,
      title: Text(
        text,
        style: enabled ? null : const TextStyle(color: Colors.white30),
      ),
      onTap: enabled
          ? () {
              onTap();
              if (hideSheetOnTap) Navigator.pop(context);
            }
          : null,
    );
  }
}

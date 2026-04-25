import 'package:app/app_state.dart';
import 'package:app/enums.dart';
import 'package:app/main.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/router.dart';
import 'package:app/ui/screens/add_to_playlist.dart';
import 'package:app/ui/screens/info_sheet/info_sheet.dart';
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
  var _downloaded = false;

  initState() {
    super.initState();

    audioHandler.queued(widget.playable).then((queued) {
      setState(() => _queued = queued);
    });

    _downloaded =
        context.read<DownloadProvider>().has(playable: widget.playable);
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
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        _QuickAction(
                          label: 'Favorite',
                          icon: playable.liked
                              ? CupertinoIcons.star_fill
                              : CupertinoIcons.star,
                          enabled: !inOfflineMode,
                          onTap: () {
                            favoriteProvider.toggleOne(playable: playable);
                            setState(() {});
                          },
                        ),
                        const _QuickActionDivider(),
                        _QuickAction(
                          label: 'Details',
                          icon: CupertinoIcons.text_quote,
                          onTap: () {
                            Navigator.pop(context);
                            showInfoSheet(context, playable: playable);
                          },
                        ),
                        const _QuickActionDivider(),
                        _QuickAction(
                          label: _downloaded ? 'Downloaded' : 'Download',
                          icon: _downloaded
                              ? CupertinoIcons.trash
                              : CupertinoIcons.cloud_download,
                          enabled: _downloaded || !inOfflineMode,
                          onTap: () async {
                            final downloadProvider =
                                context.read<DownloadProvider>();
                            if (_downloaded) {
                              await downloadProvider
                                  .removeForPlayable(playable);
                              if (mounted) setState(() => _downloaded = false);
                            } else {
                              await downloadProvider.download(
                                  playable: playable);
                              if (mounted) setState(() => _downloaded = true);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(indent: 16, endIndent: 16),
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
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _QuickAction({
    Key? key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = enabled ? Colors.white : Colors.white30;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 26, color: color),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionDivider extends StatelessWidget {
  const _QuickActionDivider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: 0.4),
            Colors.transparent,
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

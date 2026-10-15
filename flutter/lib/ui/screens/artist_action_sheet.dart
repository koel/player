import 'package:app/main.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/screens/edit_artist_sheet.dart';
import 'package:app/ui/screens/playable_action_sheet.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:app/utils/features.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ArtistActionSheet extends StatefulWidget {
  final Artist artist;

  const ArtistActionSheet({Key? key, required this.artist}) : super(key: key);

  @override
  State<ArtistActionSheet> createState() => _ArtistActionSheetState();
}

class _ArtistActionSheetState extends State<ArtistActionSheet> {
  Future<List<Playable>> _fetchSongs() {
    return context.read<PlayableProvider>().fetchForArtist(widget.artist.id);
  }

  @override
  Widget build(BuildContext context) {
    final artist = widget.artist;
    final artistProvider = context.read<ArtistProvider>();
    // Favoriting non-song entities only landed in koel 7.11.0.
    final showFavorite = Feature.favoriteEntities.isSupported();

    return FrostedGlassBackground(
      sigma: 40.0,
      child: Container(
        padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const SizedBox.shrink(),
            Column(
              children: [
                ClipOval(
                  child: Image(
                    image: artist.image,
                    width: 192,
                    height: 192,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    artist.name,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
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
                        if (showFavorite) ...[
                          PlayableQuickAction(
                            label: artist.favorite
                                ? 'Undo Favorite'
                                : 'Favorite',
                            icon: Icon(artist.favorite
                                ? CupertinoIcons.star_fill
                                : CupertinoIcons.star),
                            onTap: () {
                              Navigator.pop(context);
                              // toggleFavorite rethrows on failure (after
                              // rolling back the optimistic flip
                              // internally). The sheet has just been
                              // popped, so swallow here to avoid an
                              // unhandled async error — the UI auto-
                              // corrects from the rollback's
                              // notifyListeners.
                              artistProvider
                                  .toggleFavorite(artist)
                                  .catchError((_) {});
                            },
                          ),
                          const PlayableQuickActionDivider(),
                        ],
                        PlayableQuickAction(
                          label: 'Play All',
                          icon: const Icon(CupertinoIcons.play_fill),
                          onTap: () async {
                            Navigator.pop(context);
                            final songs = await _fetchSongs();
                            if (songs.isEmpty) return;
                            await audioHandler.replaceQueue(songs);
                          },
                        ),
                        const PlayableQuickActionDivider(),
                        PlayableQuickAction(
                          label: 'Shuffle All',
                          icon: const Icon(CupertinoIcons.shuffle),
                          onTap: () async {
                            Navigator.pop(context);
                            final songs = await _fetchSongs();
                            if (songs.isEmpty) return;
                            await audioHandler.replaceQueue(
                              songs,
                              shuffle: true,
                            );
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
                    PlayableActionButton(
                      text: 'Play Next',
                      icon: const Icon(
                        CupertinoIcons.arrow_right_circle_fill,
                        color: Colors.white30,
                      ),
                      onTap: () async {
                        final songs = await _fetchSongs();
                        // queueAfterCurrent inserts each song at the
                        // same 'after current' index, so iterating
                        // forward would reverse the artist's songs.
                        // Iterate backward so the resulting queue
                        // order matches the source order.
                        for (final song in songs.reversed) {
                          await audioHandler.queueAfterCurrent(song);
                        }
                        if (!mounted) return;
                        showOverlay(
                          context,
                          icon: CupertinoIcons.arrow_right_circle_fill,
                          caption: 'Queued',
                          message: 'To be played next.',
                        );
                      },
                    ),
                    PlayableActionButton(
                      text: 'Play Last',
                      icon: const Icon(
                        CupertinoIcons.arrow_down_right_circle_fill,
                        color: Colors.white30,
                      ),
                      onTap: () async {
                        final songs = await _fetchSongs();
                        for (final song in songs) {
                          await audioHandler.queueToBottom(song);
                        }
                        if (!mounted) return;
                        showOverlay(
                          context,
                          icon: CupertinoIcons.arrow_down_right_circle_fill,
                          caption: 'Queued',
                          message: 'Queued to bottom.',
                        );
                      },
                    ),
                    if (artist.canEdit) ...[
                      const Divider(indent: 16, endIndent: 16),
                      PlayableActionButton(
                        text: 'Edit…',
                        icon: const Icon(
                          CupertinoIcons.pencil,
                          color: Colors.white30,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          showEditArtistDialog(context, artist: artist);
                        },
                        hideSheetOnTap: false,
                      ),
                    ],
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

Future<void> showArtistActionSheet(
  BuildContext context, {
  required Artist artist,
}) {
  return showModalBottomSheet<void>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    builder: (_) => ArtistActionSheet(artist: artist),
  );
}

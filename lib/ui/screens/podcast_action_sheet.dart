import 'package:app/main.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/screens/playable_action_sheet.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:app/utils/features.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PodcastActionSheet extends StatefulWidget {
  final Podcast podcast;

  const PodcastActionSheet({Key? key, required this.podcast}) : super(key: key);

  @override
  State<PodcastActionSheet> createState() => _PodcastActionSheetState();
}

class _PodcastActionSheetState extends State<PodcastActionSheet> {
  Future<List<Playable>> _fetchEpisodes({bool getUpdates = false}) {
    return context.read<PlayableProvider>().fetchForPodcast(
          widget.podcast.id,
          forceRefresh: getUpdates,
          getUpdates: getUpdates,
        );
  }

  @override
  Widget build(BuildContext context) {
    final podcast = widget.podcast;
    final podcastProvider = context.read<PodcastProvider>();
    // Favoriting non-song entities only landed in koel 7.11.0.
    final showFavorite = Feature.favoriteEntities.isSupported();
    // Continue if there's a known last-played episode for this podcast,
    // otherwise start from the top.
    final hasInProgress = podcast.state.currentEpisodeId != null;
    final playLabel = hasInProgress ? 'Continue' : 'Play All';

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
                ClipSmoothRect(
                  radius: SmoothBorderRadius(
                    cornerRadius: 24,
                    cornerSmoothing: .8,
                  ),
                  child: Image(
                    image: podcast.image,
                    width: 192,
                    height: 192,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    podcast.title,
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
                    podcast.author,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
                if (podcast.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      podcast.description,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
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
                            label: podcast.favorite
                                ? 'Undo Favorite'
                                : 'Favorite',
                            icon: Icon(podcast.favorite
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
                              podcastProvider
                                  .toggleFavorite(podcast)
                                  .catchError((_) {});
                            },
                          ),
                          const PlayableQuickActionDivider(),
                        ],
                        PlayableQuickAction(
                          label: playLabel,
                          icon: const Icon(CupertinoIcons.play_fill),
                          onTap: () async {
                            Navigator.pop(context);
                            final episodes = await _fetchEpisodes();
                            if (episodes.isEmpty) return;

                            final currentId = podcast.state.currentEpisodeId;
                            final current = currentId == null
                                ? null
                                : episodes.cast<Playable?>().firstWhere(
                                      (e) => e?.id == currentId,
                                      orElse: () => null,
                                    );

                            if (current == null) {
                              await audioHandler.replaceQueue(episodes);
                            } else {
                              // Queue all episodes silently, then jump to
                              // the in-progress one. maybeQueueAndPlay
                              // restores its saved playback position.
                              await audioHandler.replaceQueue(
                                episodes,
                                autoPlay: false,
                              );
                              await audioHandler.maybeQueueAndPlay(current);
                            }
                          },
                        ),
                        const PlayableQuickActionDivider(),
                        PlayableQuickAction(
                          label: 'Shuffle',
                          icon: const Icon(CupertinoIcons.shuffle),
                          onTap: () async {
                            Navigator.pop(context);
                            final episodes = await _fetchEpisodes();
                            if (episodes.isEmpty) return;
                            await audioHandler.replaceQueue(
                              episodes,
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
                      text: 'Refresh',
                      icon: const Icon(
                        CupertinoIcons.arrow_clockwise,
                        color: Colors.white30,
                      ),
                      onTap: () async {
                        await _fetchEpisodes(getUpdates: true);
                        if (!mounted) return;
                        showOverlay(
                          context,
                          icon: CupertinoIcons.arrow_clockwise,
                          caption: 'Feed refreshed',
                        );
                      },
                    ),
                    const Divider(indent: 16, endIndent: 16),
                    PlayableActionButton(
                      text: 'Unsubscribe',
                      destructive: true,
                      icon: const Icon(CupertinoIcons.minus_circle),
                      onTap: () async {
                        if (!await confirmUnsubscribePodcast(
                          context,
                          podcast: podcast,
                        )) {
                          return;
                        }
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        await unsubscribePodcastWithFeedback(
                          context,
                          podcast: podcast,
                        );
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

Future<void> showPodcastActionSheet(
  BuildContext context, {
  required Podcast podcast,
}) {
  return showModalBottomSheet<void>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    builder: (_) => PodcastActionSheet(podcast: podcast),
  );
}

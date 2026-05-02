import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/screens/edit_radio_station_sheet.dart';
import 'package:app/ui/screens/playable_action_sheet.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:app/utils/features.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RadioStationActionSheet extends StatelessWidget {
  final RadioStation station;

  const RadioStationActionSheet({Key? key, required this.station})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stationProvider = context.read<RadioStationProvider>();
    // Favoriting non-song entities only landed in koel 7.11.0.
    final showFavorite = Feature.favoriteEntities.isSupported();
    final hasDescription =
        station.description != null && station.description!.isNotEmpty;

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
                _Thumbnail(station: station, dimension: 192),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    station.name,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (hasDescription) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      station.description!,
                      textAlign: TextAlign.center,
                      softWrap: true,
                      style: const TextStyle(color: Colors.white54),
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
                            label: station.favorite
                                ? 'Undo Favorite'
                                : 'Favorite',
                            icon: Icon(station.favorite
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
                              stationProvider
                                  .toggleFavorite(station)
                                  .catchError((_) {});
                            },
                          ),
                          const PlayableQuickActionDivider(),
                        ],
                        Consumer<RadioPlayerProvider>(
                          builder: (_, radioPlayer, __) {
                            final isCurrent =
                                radioPlayer.currentStation?.id == station.id;
                            final isStopButton = isCurrent &&
                                (radioPlayer.playing || radioPlayer.loading);

                            return PlayableQuickAction(
                              label: isStopButton ? 'Stop' : 'Play',
                              icon: Icon(isStopButton
                                  ? CupertinoIcons.stop_fill
                                  : CupertinoIcons.play_fill),
                              onTap: () {
                                Navigator.pop(context);
                                if (isStopButton) {
                                  radioPlayer.stop();
                                } else {
                                  radioPlayer
                                      .play(station)
                                      .catchError((_) {});
                                }
                              },
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
                    if (station.canEdit)
                      PlayableActionButton(
                        text: 'Edit…',
                        icon: const Icon(
                          CupertinoIcons.pencil,
                          color: Colors.white30,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          showEditRadioStationDialog(context, station: station);
                        },
                        hideSheetOnTap: false,
                      ),
                    if (station.canDelete) ...[
                      if (station.canEdit)
                        const Divider(indent: 16, endIndent: 16),
                      PlayableActionButton(
                        text: 'Delete',
                        destructive: true,
                        icon: const Icon(
                          CupertinoIcons.trash,
                          color: Colors.white30,
                        ),
                        onTap: () async {
                          if (!await confirmDeleteRadioStation(
                            context,
                            station: station,
                          )) {
                            return;
                          }
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          deleteRadioStationWithFeedback(
                            context,
                            station: station,
                          );
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

class _Thumbnail extends StatelessWidget {
  final RadioStation station;
  final double dimension;

  const _Thumbnail({required this.station, required this.dimension});

  @override
  Widget build(BuildContext context) {
    Widget fallback() => Container(
          width: dimension,
          height: dimension,
          color: Colors.white12,
          child: Icon(
            CupertinoIcons.antenna_radiowaves_left_right,
            size: dimension * 0.4,
            color: Colors.white54,
          ),
        );

    return ClipSmoothRect(
      radius: SmoothBorderRadius(
        cornerRadius: 24,
        cornerSmoothing: .8,
      ),
      child: SizedBox(
        width: dimension,
        height: dimension,
        child: station.logo != null
            ? CachedNetworkImage(
                imageUrl: station.logo!,
                width: dimension,
                height: dimension,
                fit: BoxFit.cover,
                placeholder: (_, __) => fallback(),
                errorWidget: (_, __, ___) => fallback(),
              )
            : fallback(),
      ),
    );
  }
}

Future<void> showRadioStationActionSheet(
  BuildContext context, {
  required RadioStation station,
}) {
  return showModalBottomSheet<void>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    builder: (_) => RadioStationActionSheet(station: station),
  );
}

import 'dart:ui';

import 'package:app/extensions/assets_audio_player.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/audio_provider.dart';
import 'package:app/providers/interaction_provider.dart';
import 'package:app/router.dart';
import 'package:app/ui/screens/add_to_playlist.dart';
import 'package:app/ui/widgets/message_overlay.dart';
import 'package:app/ui/widgets/song_thumbnail.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SongActionSheet extends StatelessWidget {
  final Song song;

  const SongActionSheet({Key? key, required this.song}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    InteractionProvider interactionProvider = context.read();
    AudioProvider audio = context.read();

    bool isCurrent = audio.player.songId == song.id;

    return FutureBuilder(
      future: audio.queued(song),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.data == null) {
          return SizedBox.shrink();
        }

        bool queued = snapshot.data!;

        return ClipRect(
          child: Container(
            padding: const EdgeInsets.only(
              top: 16.0,
              bottom: 8.0,
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40.0, sigmaY: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  SizedBox.shrink(), // to properly align the thumbnail area
                  Column(
                    children: [
                      SongThumbnail(
                        song: song,
                        size: ThumbnailSize.lg,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        song.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          '${song.artist.name} • ${song.album.name}',
                          overflow: TextOverflow.ellipsis,
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
                        SongActionButton(
                          text: 'Play Next',
                          icon: const Icon(
                            CupertinoIcons.arrow_right_circle_fill,
                            color: Colors.white30,
                          ),
                          onTap: () {
                            audio.queueAfterCurrent(song: song);
                            showOverlay(
                              context,
                              icon: CupertinoIcons.arrow_right_circle_fill,
                              caption: 'Queued',
                              message: 'Song to be played next.',
                            );
                          },
                        ),
                      if (!isCurrent)
                        SongActionButton(
                          text: 'Play Last',
                          icon: const Icon(
                            CupertinoIcons.arrow_down_right_circle_fill,
                            color: Colors.white30,
                          ),
                          onTap: () {
                            audio.queueToBottom(song: song);
                            showOverlay(
                              context,
                              icon: CupertinoIcons.arrow_down_right_circle_fill,
                              caption: 'Queued',
                              message: 'Song queued to bottom.',
                            );
                          },
                        ),
                      if (queued)
                        SongActionButton(
                          text: 'Remove from Queue',
                          icon: const Icon(
                            CupertinoIcons.text_badge_minus,
                            color: Colors.white30,
                          ),
                          onTap: () {
                            audio.removeFromQueue(song: song);
                            showOverlay(
                              context,
                              icon: CupertinoIcons.text_badge_minus,
                              caption: 'Removed',
                              message: 'Song removed from queue.',
                            );
                          },
                        ),
                      SongActionButton(
                        text: song.liked
                            ? 'Remove as Favorite'
                            : 'Mark as Favorite',
                        icon: Icon(
                          song.liked
                              ? CupertinoIcons.heart_fill
                              : CupertinoIcons.heart,
                          color: Colors.white30,
                        ),
                        onTap: () {
                          showOverlay(
                            context,
                            caption: song.liked ? 'Unliked' : 'Liked',
                            message: song.liked
                                ? 'Song removed from Favorites.'
                                : 'Song added to Favorites.',
                            icon: song.liked
                                ? CupertinoIcons.heart_slash
                                : CupertinoIcons.heart_fill,
                          );
                          interactionProvider.toggleLike(song: song);
                        },
                      ),
                      const Divider(indent: 16, endIndent: 16),
                      SongActionButton(
                        text: 'Go to Album',
                        icon: const Icon(
                          CupertinoIcons.music_albums_fill,
                          color: Colors.white30,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          AppRouter().gotoAlbumDetailsScreen(
                            context,
                            album: song.album,
                          );
                        },
                        hideSheetOnTap: false,
                      ),
                      SongActionButton(
                        text: 'Go to Artist',
                        icon: const Icon(
                          CupertinoIcons.music_mic,
                          color: Colors.white30,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          AppRouter().gotoArtistDetailsScreen(context,
                              artist: song.artist);
                        },
                        hideSheetOnTap: false,
                      ),
                      const Divider(indent: 16, endIndent: 16),
                      SongActionButton(
                        text: 'Add to a Playlist…',
                        icon: const Icon(
                          CupertinoIcons.text_badge_plus,
                          color: Colors.white30,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          gotoAddToPlaylistScreen(context, song: song);
                        },
                        hideSheetOnTap: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class SongActionButton extends StatelessWidget {
  final String text;
  final Icon icon;
  final Function onTap;
  final bool hideSheetOnTap;

  const SongActionButton({
    Key? key,
    required this.text,
    required this.icon,
    required this.onTap,
    this.hideSheetOnTap = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon,
      minLeadingWidth: 16,
      title: Text(text),
      onTap: () {
        onTap();

        if (hideSheetOnTap) {
          Navigator.pop(context);
        }
      },
    );
  }
}

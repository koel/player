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

Future<void> showActionSheet({
  required BuildContext context,
  required Song song,
}) async {
  InteractionProvider interactionProvider = context.read();
  AudioProvider audio = context.read();

  bool queued = await audio.queued(song);
  bool isCurrent = audio.player.songId == song.id;

  showModalBottomSheet<void>(
    useRootNavigator: true, // covering everything else
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      Widget _button({
        required String text,
        required Icon icon,
        required Function onTap,
        bool hideSheetOnTap = true,
      }) {
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

      List<Widget> menuItems = [
        if (!isCurrent)
          _button(
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
          _button(
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
          _button(
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
        _button(
          text: song.liked ? 'Remove as Favorite' : 'Mark as Favorite',
          icon: Icon(
            song.liked ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
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
        _button(
          text: 'Go to Album',
          icon: const Icon(
            CupertinoIcons.music_albums_fill,
            color: Colors.white30,
          ),
          onTap: () {
            Navigator.pop(context);
            AppRouter().gotoAlbumDetailsScreen(context, album: song.album);
          },
          hideSheetOnTap: false,
        ),
        _button(
          text: 'Go to Artist',
          icon: const Icon(
            CupertinoIcons.music_mic,
            color: Colors.white30,
          ),
          onTap: () {
            Navigator.pop(context);
            AppRouter().gotoArtistDetailsScreen(context, artist: song.artist);
          },
          hideSheetOnTap: false,
        ),
        const Divider(indent: 16, endIndent: 16),
        _button(
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
      ];

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
                const SizedBox.shrink(), // to properly align the thumbnail area
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
                  children: menuItems,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

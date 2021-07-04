import 'dart:ui';

import 'package:app/models/song.dart';
import 'package:app/providers/audio_player_provider.dart';
import 'package:app/providers/interaction_provider.dart';
import 'package:app/ui/screens/add_to_playlist.dart';
import 'package:app/ui/screens/album_details.dart';
import 'package:app/ui/screens/artist_details.dart';
import 'package:app/ui/widgets/song_thumbnail.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> showActionSheet({
  required BuildContext context,
  required Song song,
}) async {
  InteractionProvider interactionProvider = context.read();
  AudioPlayerProvider audio = context.read();

  bool queued = await audio.queued(song);
  bool isCurrent = audio.player.getCurrentAudioextra['songId'] == song.id;

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
          leading: Opacity(opacity: .3, child: icon),
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

      List<Widget> menuItems = [];

      if (!isCurrent) {
        menuItems.add(
          _button(
            text: 'Play Next',
            icon: Icon(CupertinoIcons.arrow_right_circle_fill),
            onTap: () => audio.queueAfterCurrent(song),
          ),
        );
        menuItems.add(
          _button(
            text: 'Play Last',
            icon: Icon(CupertinoIcons.arrow_down_right_circle_fill),
            onTap: () => audio.queueToBottom(song),
          ),
        );
      }

      if (queued) {
        menuItems.add(
          _button(
            text: 'Remove from Queue',
            icon: Icon(CupertinoIcons.text_badge_minus),
            onTap: () => audio.removeFromQueue(song),
          ),
        );
      }

      menuItems.add(
        _button(
          text: song.liked ? 'Unlike' : 'Like',
          icon: Icon(song.liked
              ? CupertinoIcons.heart_slash
              : CupertinoIcons.heart_fill),
          onTap: () => interactionProvider.toggleLike(song),
        ),
      );

      menuItems.add(Divider(
        indent: 16,
        endIndent: 16,
      ));

      menuItems.add(
        _button(
          text: 'Go to Album',
          icon: Icon(CupertinoIcons.music_albums_fill),
          onTap: () {
            Navigator.pop(context);
            Navigator.of(context).push(CupertinoPageRoute<void>(
              builder: (_) => AlbumDetailsScreen(album: song.album),
            ));
          },
          hideSheetOnTap: false,
        ),
      );

      menuItems.add(
        _button(
          text: 'Go to Artist',
          icon: Icon(CupertinoIcons.music_mic),
          onTap: () {
            Navigator.pop(context);
            Navigator.of(context).push(CupertinoPageRoute<void>(
              builder: (_) => ArtistDetailsScreen(artist: song.artist),
              title: song.artist.name,
            ));
          },
          hideSheetOnTap: false,
        ),
      );

      menuItems.add(Divider(
        indent: 16,
        endIndent: 16,
      ));

      menuItems.add(
        _button(
          text: 'Add to a Playlist…',
          icon: Icon(CupertinoIcons.text_badge_plus),
          onTap: () {
            Navigator.pop(context);
            Navigator.of(context).push(CupertinoPageRoute<void>(
              builder: (_) => AddToPlaylistScreen(song: song),
              title: 'Add to a Playlist',
            ));
          },
          hideSheetOnTap: false,
        ),
      );

      return ClipRect(
        child: Container(
          padding: EdgeInsets.only(bottom: 8),
          child: BackdropFilter(
            filter: new ImageFilter.blur(sigmaX: 40.0, sigmaY: 40.0),
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
                    SizedBox(height: 16),
                    Text(
                      song.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Opacity(
                      opacity: .5,
                      child: Text(
                        '${song.artist.name} • ${song.album.name}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
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

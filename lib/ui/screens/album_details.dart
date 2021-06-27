import 'dart:ui';

import 'package:app/constants/dimens.dart';
import 'package:app/models/album.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/audio_player_provider.dart';
import 'package:app/providers/song_provider.dart';
import 'package:app/ui/widgets/song_list.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AlbumDetailsScreen extends StatelessWidget {
  final Album album;

  AlbumDetailsScreen({Key? key, required this.album}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    AudioPlayerProvider audio = context.watch<AudioPlayerProvider>();
    List<Song> songs = context.watch<SongProvider>().byAlbum(album)
      ..sort((a, b) => a.title.compareTo(b.title));

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            expandedHeight: 290,
            flexibleSpace: FlexibleSpaceBar(
              title: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(album.name, overflow: TextOverflow.ellipsis),
              ),
              background: Stack(
                children: <Widget>[
                  SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: album.image,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: SizedBox(
                      width: 192,
                      height: 192,
                      child: Hero(
                        tag: "album-hero-${album.id}",
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: album.image,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.3),
                                blurRadius: 10.0,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.all(AppDimens.horizontalPadding),
              child: Row(
                children: <Widget>[
                  DetailsScreenButton(
                    icon: CupertinoIcons.play_fill,
                    onPressed: () async => await audio.replaceQueue(songs),
                  ),
                  SizedBox(width: 12),
                  DetailsScreenButton(
                    icon: CupertinoIcons.shuffle,
                    onPressed: () async =>
                        await audio.replaceQueue(songs, shuffle: true),
                  ),
                ],
              ),
            ),
          ),
          SongList(songs: songs),
        ],
      ),
    );
  }
}

class DetailsScreenButton extends StatelessWidget {
  late final AudioPlayerProvider audio;
  final VoidCallback onPressed;
  final IconData icon;

  DetailsScreenButton({
    Key? key,
    required this.onPressed,
    required this.icon,
  }) : super(key: key);

  final ButtonStyle _buttonStyle = ElevatedButton.styleFrom(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
    ),
    primary: Colors.grey.shade900,
    onPrimary: Colors.red,
    textStyle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
  );

  @override
  Widget build(BuildContext context) {
    audio = context.watch<AudioPlayerProvider>();

    return Expanded(
      child: ConstrainedBox(
        constraints: BoxConstraints.expand(
          width: double.infinity,
          height: 48,
        ),
        child: ElevatedButton(
          style: _buttonStyle,
          onPressed: onPressed,
          child: Row(
            children: <Widget>[
              Icon(icon, size: 20),
              Expanded(
                child: Text(
                  'Play All',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:ui';

import 'package:app/models/playlist.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/playlist_provider.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/song_list.dart';
import 'package:app/ui/widgets/song_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlaylistDetailsScreen extends StatefulWidget {
  final Playlist playlist;

  PlaylistDetailsScreen({Key? key, required this.playlist}) : super(key: key);

  @override
  _PlaylistDetailsScreen createState() => _PlaylistDetailsScreen();
}

class _PlaylistDetailsScreen extends State<PlaylistDetailsScreen> {
  late PlaylistProvider playlistProvider;
  late Future<Playlist> futurePlaylist;

  @override
  void initState() {
    super.initState();
    playlistProvider = context.read();
    futurePlaylist = playlistProvider.populatePlaylist(
      playlist: widget.playlist,
    );
  }

  Widget coverImage({required ImageProvider image, double overlayOpacity = 0}) {
    return SizedBox(
      width: 160,
      height: 160,
      child: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(overlayOpacity),
              BlendMode.srcOver,
            ),
            image: image,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          borderRadius: BorderRadius.all(Radius.circular(8)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(.3),
              blurRadius: 10.0,
              offset: Offset(0, 6),
            ),
          ],
        ),
      ),
    );
  }

  Widget coverImageStack({required Playlist playlist}) {
    const imageCount = 4;
    List<ImageProvider> images = [];

    if (!playlist.isEmpty) {
      images = playlist.songs
          .where((song) {
            return song.image is NetworkImage &&
                !(song.image as NetworkImage).url.endsWith('unknown-album.png');
          })
          .map((song) => song.image)
          .toList();

      images.shuffle();
      images = images.take(imageCount).toList();
    }

    // fill up to 4 images
    for (int i = images.length; i < imageCount; ++i) {
      images.insert(0, AssetImage('assets/images/unknown-album.png'));
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -16,
          top: -24,
          child: coverImage(image: images[0], overlayOpacity: .8),
        ),
        Positioned(
          left: 32,
          top: -16,
          child: coverImage(image: images[1], overlayOpacity: .6),
        ),
        Positioned(
          left: 14,
          top: 20,
          child: coverImage(image: images[2], overlayOpacity: .4),
        ),
        coverImage(image: images[3]),
      ],
    );
  }

  Widget appBar({required Playlist playlist}) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 290,
      flexibleSpace: FlexibleSpaceBar(
        title: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            widget.playlist.name,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        background: Stack(
          children: <Widget>[
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
                child: coverImageStack(playlist: playlist),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: futurePlaylist,
        builder: (BuildContext context, AsyncSnapshot<Playlist> snapshot) {
          if (!snapshot.hasData || snapshot.hasError) {
            return CustomScrollView(
              slivers: <Widget>[appBar(playlist: widget.playlist)],
            );
          }

          Playlist playlist = snapshot.data!;

          return CustomScrollView(
            slivers: <Widget>[
              appBar(playlist: playlist),
              SliverToBoxAdapter(
                child: playlist.isEmpty
                    ? const SizedBox.shrink()
                    : songListButtons(context, songs: playlist.songs),
              ),
              playlist.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: Center(
                          child: Text(
                            'The playlist is empty.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(.5),
                            ),
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, int index) {
                          final bool dismissible = widget.playlist.isSmart;
                          final Song song = widget.playlist.songs[index];
                          return Dismissible(
                            direction: dismissible
                                ? DismissDirection.none
                                : DismissDirection.endToStart,
                            onDismissed: dismissible
                                ? null
                                : (DismissDirection direction) =>
                                    playlistProvider.removeSongFromPlaylist(
                                      song: song,
                                      playlist: widget.playlist,
                                    ),
                            background: Container(
                              alignment: AlignmentDirectional.centerEnd,
                              color: Colors.red,
                              child: const Padding(
                                padding: EdgeInsets.only(right: 28),
                                child: Icon(CupertinoIcons.delete_simple),
                              ),
                            ),
                            key: ValueKey(song),
                            child: SongRow(
                              key: ValueKey(song),
                              song: song,
                            ),
                          );
                        },
                        childCount: playlist.songs.length,
                      ),
                    ),
              SliverToBoxAdapter(child: bottomSpace()),
            ],
          );
        },
      ),
    );
  }
}

void gotoDetailsScreen(BuildContext context, {required Playlist playlist}) {
  Navigator.of(context).push(CupertinoPageRoute<void>(
    builder: (_) => PlaylistDetailsScreen(playlist: playlist),
    title: playlist.name,
  ));
}

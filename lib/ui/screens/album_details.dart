import 'dart:ui';

import 'package:app/models/album.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/song_provider.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/song_list.dart';
import 'package:app/ui/widgets/song_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AlbumDetailsScreen extends StatelessWidget {
  final Album album;

  AlbumDetailsScreen({Key? key, required this.album}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  const SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: const DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: const <Color>[
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
                            borderRadius: const BorderRadius.all(
                              Radius.circular(16),
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withOpacity(.3),
                                blurRadius: 10.0,
                                offset: const Offset(0, 6),
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
          SliverToBoxAdapter(child: SongListButtons(songs: songs)),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, int index) => SongRow(song: songs[index]),
              childCount: songs.length,
            ),
          ),
          SliverToBoxAdapter(child: bottomSpace()),
        ],
      ),
    );
  }
}

void gotoDetailsScreen(BuildContext context, {required Album album}) {
  Navigator.of(context).push(CupertinoPageRoute<void>(
    builder: (_) => AlbumDetailsScreen(album: album),
    title: album.name,
  ));
}

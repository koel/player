import 'dart:ui';

import 'package:app/models/artist.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/song_provider.dart';
import 'package:app/ui/widgets/app_bar.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/song_list.dart';
import 'package:app/ui/widgets/song_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide AppBar;
import 'package:provider/provider.dart';

class ArtistDetailsScreen extends StatelessWidget {
  final Artist artist;

  ArtistDetailsScreen({Key? key, required this.artist}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Song> songs = context.watch<SongProvider>().byArtist(artist)
      ..sort((a, b) => a.title.compareTo(b.title));

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          AppBar(
            headingText: artist.name,
            backgroundImage: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: artist.image,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
            ),
            coverImage: Hero(
              tag: "artist-hero-${artist.id}",
              child: DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: artist.image,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(16),
                  ),
                  boxShadow: const <BoxShadow>[
                    const BoxShadow(
                      color: Colors.black38,
                      blurRadius: 10.0,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
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

void gotoDetailsScreen(BuildContext context, {required Artist artist}) {
  Navigator.of(context).push(CupertinoPageRoute<void>(
    builder: (_) => ArtistDetailsScreen(artist: artist),
    title: artist.name,
  ));
}

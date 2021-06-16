import 'dart:ui';

import 'package:app/models/artist.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/song_provider.dart';
import 'package:app/ui/widgets/heading_1.dart';
import 'package:app/ui/widgets/song_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ArtistDetailsScreen extends StatelessWidget {
  final Artist artist;

  ArtistDetailsScreen(this.artist, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Song> _songs = Provider.of<SongProvider>(context).byArtist(artist);
    _songs.sort((a, b) => a.title.compareTo(b.title));

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            expandedHeight: 256,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(artist.name),
              background: Hero(
                tag: "artist-hero-${artist.id}",
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
                ),),
              ),
            ),
          ),
          SongList(_songs),
        ],
      ),
    );
  }
}

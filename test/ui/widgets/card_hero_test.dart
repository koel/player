import 'package:app/models/album.dart';
import 'package:app/models/artist.dart';
import 'package:app/providers/album_provider.dart';
import 'package:app/providers/artist_provider.dart';
import 'package:app/ui/widgets/album_artist_thumbnail.dart';
import 'package:app/ui/widgets/album_card.dart';
import 'package:app/ui/widgets/artist_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../extensions/widget_tester_extension.dart';

void main() {
  Finder heroWithTag(Object tag) =>
      find.byWidgetPredicate((widget) => widget is Hero && widget.tag == tag);

  testWidgets('an album card omits the hero when asHero is false',
      (tester) async {
    final album = Album.fake();

    await tester.pumpAppWidget(
      ChangeNotifierProvider<AlbumProvider>(
        create: (_) => AlbumProvider(),
        child: AlbumCard(album: album, asHero: false),
      ),
    );

    expect(heroWithTag(AlbumArtistThumbnail.tagForEntity(album)), findsNothing);
  });

  testWidgets('a repeated album yields a single hero tag across cards',
      (tester) async {
    final album = Album.fake();

    await tester.pumpAppWidget(
      ChangeNotifierProvider<AlbumProvider>(
        create: (_) => AlbumProvider(),
        child: SingleChildScrollView(
          child: Column(
            children: [
              AlbumCard(album: album, asHero: true),
              AlbumCard(album: album, asHero: false),
            ],
          ),
        ),
      ),
    );

    expect(
      heroWithTag(AlbumArtistThumbnail.tagForEntity(album)),
      findsOneWidget,
    );
  });

  testWidgets('a repeated artist yields a single hero tag across cards',
      (tester) async {
    final artist = Artist.fake();

    await tester.pumpAppWidget(
      ChangeNotifierProvider<ArtistProvider>(
        create: (_) => ArtistProvider(),
        child: SingleChildScrollView(
          child: Column(
            children: [
              ArtistCard(artist: artist, asHero: true),
              ArtistCard(artist: artist, asHero: false),
            ],
          ),
        ),
      ),
    );

    expect(
      heroWithTag(AlbumArtistThumbnail.tagForEntity(artist)),
      findsOneWidget,
    );
  });
}

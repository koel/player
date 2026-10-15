import 'package:app/models/album.dart';
import 'package:app/models/artist.dart';
import 'package:app/ui/widgets/album_artist_thumbnail.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../extensions/widget_tester_extension.dart';

void main() {
  group('AlbumArtistThumbnail', () {
    testWidgets('uses ClipOval for artists', (tester) async {
      final artist = Artist.fake(name: 'Test Artist');

      await tester.pumpAppWidget(
        AlbumArtistThumbnail.sm(entity: artist),
      );

      expect(find.byType(ClipOval), findsOneWidget);
      expect(find.byType(ClipSmoothRect), findsNothing);
    });

    testWidgets('uses ClipSmoothRect for albums', (tester) async {
      final album = Album.fake(name: 'Test Album');

      await tester.pumpAppWidget(
        AlbumArtistThumbnail.sm(entity: album),
      );

      expect(find.byType(ClipSmoothRect), findsOneWidget);
      expect(find.byType(ClipOval), findsNothing);
    });
  });
}

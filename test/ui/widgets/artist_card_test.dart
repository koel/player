import 'package:app/models/artist.dart';
import 'package:app/providers/artist_provider.dart';
import 'package:app/router.dart';
import 'package:app/ui/widgets/album_artist_thumbnail.dart';
import 'package:app/ui/widgets/artist_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../../extensions/widget_tester_extension.dart';
import 'artist_card_test.mocks.dart';

Future<void> _pump(WidgetTester tester, Widget child, ArtistProvider provider) =>
    tester.pumpAppWidget(
      ChangeNotifierProvider<ArtistProvider>.value(value: provider, child: child),
    );

@GenerateMocks([AppRouter])
void main() {
  late Artist artist;
  late ArtistProvider provider;

  setUp(() {
    artist = Artist.fake(name: 'Banana');
    provider = ArtistProvider();
    provider.syncWithVault([artist]);
  });

  testWidgets('renders', (tester) async {
    await _pump(tester, ArtistCard(artist: artist), provider);

    expect(find.byType(AlbumArtistThumbnail), findsOneWidget);
    expect(find.text('Banana'), findsOneWidget);
  });

  testWidgets('goes to Artist Details screen', (tester) async {
    final router = MockAppRouter();
    when(
      router.gotoArtistDetailsScreen(any, artistId: artist.id),
    ).thenAnswer((_) async => null);

    await _pump(tester, ArtistCard(artist: artist, router: router), provider);

    await tester.tap(find.text('Banana'));
    verify(router.gotoArtistDetailsScreen(any, artistId: artist.id)).called(1);
  });

  testWidgets('rebuilds when ArtistProvider notifies', (tester) async {
    await _pump(tester, ArtistCard(artist: artist), provider);
    expect(find.text('Banana'), findsOneWidget);

    artist.name = 'Renamed';
    provider.notifyListeners();
    await tester.pump();

    expect(find.text('Renamed'), findsOneWidget);
    expect(find.text('Banana'), findsNothing);
  });
}

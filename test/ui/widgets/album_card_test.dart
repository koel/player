import 'package:app/models/album.dart';
import 'package:app/models/artist.dart';
import 'package:app/providers/album_provider.dart';
import 'package:app/router.dart';
import 'package:app/ui/widgets/album_artist_thumbnail.dart';
import 'package:app/ui/widgets/album_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../../extensions/widget_tester_extension.dart';
import 'album_card_test.mocks.dart';

Future<void> _pump(WidgetTester tester, Widget child, AlbumProvider provider) =>
    tester.pumpAppWidget(
      ChangeNotifierProvider<AlbumProvider>.value(value: provider, child: child),
    );

@GenerateMocks([AppRouter])
void main() {
  late Album album;
  late AlbumProvider provider;

  setUp(() {
    album = Album.fake(
      name: 'A Whole New Bunch',
      artist: Artist.fake(name: 'Banana'),
    );
    provider = AlbumProvider();
    provider.syncWithVault([album]);
  });

  testWidgets('renders', (tester) async {
    await _pump(tester, AlbumCard(album: album), provider);

    expect(find.byType(AlbumArtistThumbnail), findsOneWidget);
    expect(find.text('Banana'), findsOneWidget);
    expect(find.text('A Whole New Bunch'), findsOneWidget);
  });

  testWidgets('goes to Album Details screen', (tester) async {
    final router = MockAppRouter();
    when(
      router.gotoAlbumDetailsScreen(any, albumId: album.id),
    ).thenAnswer((_) async => null);

    await _pump(tester, AlbumCard(album: album, router: router), provider);

    await tester.tap(find.text('A Whole New Bunch'));
    verify(router.gotoAlbumDetailsScreen(any, albumId: album.id)).called(1);
  });

  testWidgets('rebuilds when AlbumProvider notifies', (tester) async {
    await _pump(tester, AlbumCard(album: album), provider);
    expect(find.text('Banana'), findsOneWidget);

    album.artistName = 'Renamed';
    provider.notifyListeners();
    await tester.pump();

    expect(find.text('Renamed'), findsOneWidget);
    expect(find.text('Banana'), findsNothing);
  });
}

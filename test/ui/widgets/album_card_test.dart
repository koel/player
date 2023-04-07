import 'package:app/models/album.dart';
import 'package:app/models/artist.dart';
import 'package:app/router.dart';
import 'package:app/ui/widgets/album_card.dart';
import 'package:app/ui/widgets/album_thumbnail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../extensions/widget_tester_extension.dart';
import 'album_card_test.mocks.dart';

@GenerateMocks([AppRouter])
void main() {
  late Album album;

  setUpAll(() {
    album = Album.fake(
      name: 'A Whole New Bunch',
      artist: Artist.fake(name: 'Banana'),
    );
  });

  testWidgets('renders', (WidgetTester tester) async {
    await tester.pumpAppWidget(AlbumCard(album: album));

    expect(find.byType(AlbumThumbnail), findsOneWidget);
    expect(find.text('Banana'), findsOneWidget);
    expect(find.text('A Whole New Bunch'), findsOneWidget);

    await expectLater(
      find.byType(AlbumCard),
      matchesGoldenFile('goldens/album_card.png'),
    );
  });

  testWidgets('goes to Album Details screen', (WidgetTester tester) async {
    MockAppRouter router = MockAppRouter();
    when(
      router.gotoAlbumDetailsScreen(any, album: album),
    ).thenAnswer((_) async => null);

    await tester.pumpAppWidget(AlbumCard(album: album, router: router));

    await tester.tap(find.text('A Whole New Bunch'));
    verify(router.gotoAlbumDetailsScreen(any, album: album)).called(1);
  });
}

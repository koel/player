import 'package:app/models/album.dart';
import 'package:app/models/artist.dart';
import 'package:app/router.dart';
import 'package:app/ui/widgets/album_card.dart';
import 'package:app/ui/widgets/album_thumbnail.dart';
import 'package:faker/faker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../extensions/widget_extension.dart';
import 'album_card_test.mocks.dart';

@GenerateMocks([AppRouter])
void main() {
  late Album _album;

  setUpAll(() {
    Faker faker = Faker();

    Artist artist = Artist(
      id: 1,
      name: 'Banana',
      imageUrl: faker.image.image(width: 192, height: 192),
    );

    _album = Album(
      id: 1,
      name: 'A Whole New Bunch',
      cover: faker.image.image(width: 192, height: 192),
      isCompilation: false,
      artistId: 1,
    )..artist = artist;
  });

  testWidgets('renders', (WidgetTester tester) async {
    await tester.pumpWidget(AlbumCard(album: _album).wrapForTest());

    expect(find.byType(AlbumThumbnail), findsOneWidget);
    expect(find.text('Banana'), findsOneWidget);
    expect(find.text('A Whole New Bunch'), findsOneWidget);

    await expectLater(
      find.byType(AlbumCard),
      matchesGoldenFile('../goldens/widgets/album_card.png'),
    );
  });

  testWidgets('goes to Album Details screen', (WidgetTester tester) async {
    MockAppRouter router = MockAppRouter();
    when(
      router.gotoAlbumDetailsScreen(any, album: _album),
    ).thenAnswer((_) async => null);

    await tester.pumpWidget(AlbumCard(
      album: _album,
      router: router,
    ).wrapForTest());

    await tester.tap(find.text('A Whole New Bunch'));
    verify(router.gotoAlbumDetailsScreen(any, album: _album)).called(1);
  });
}

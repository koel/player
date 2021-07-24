import 'package:app/models/artist.dart';
import 'package:app/router.dart';
import 'package:app/ui/widgets/artist_card.dart';
import 'package:app/ui/widgets/artist_thumbnail.dart';
import 'package:faker/faker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../extensions/widget_extension.dart';
import 'artist_card_test.mocks.dart';

@GenerateMocks([AppRouter])
void main() {
  late Artist _artist;

  setUpAll(() {
    Faker faker = Faker();

    _artist = Artist(
      id: 1,
      name: 'Banana',
      imageUrl: faker.image.image(width: 192, height: 192),
    );
  });

  testWidgets('renders', (WidgetTester tester) async {
    await tester.pumpWidget(ArtistCard(artist: _artist).wrapForTest());

    expect(find.byType(ArtistThumbnail), findsOneWidget);
    expect(find.text('Banana'), findsOneWidget);

    await expectLater(
      find.byType(ArtistCard),
      matchesGoldenFile('../goldens/widgets/artist_card.png'),
    );
  });

  testWidgets('goes to Artist Details screen', (WidgetTester tester) async {
    MockAppRouter router = MockAppRouter();
    when(
      router.gotoArtistDetailsScreen(any, artist: _artist),
    ).thenAnswer((_) async => null);

    await tester.pumpWidget(ArtistCard(
      artist: _artist,
      router: router,
    ).wrapForTest());

    await tester.tap(find.text('Banana'));
    verify(router.gotoArtistDetailsScreen(any, artist: _artist)).called(1);
  });
}

import 'package:app/models/artist.dart';
import 'package:app/router.dart';
import 'package:app/ui/widgets/artist_card.dart';
import 'package:app/ui/widgets/artist_thumbnail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../extensions/widget_tester_extension.dart';
import 'artist_card_test.mocks.dart';

@GenerateMocks([AppRouter])
void main() {
  late Artist artist;

  setUpAll(() {
    artist = Artist.fake(name: 'Banana');
  });

  testWidgets('renders', (WidgetTester tester) async {
    await tester.pumpAppWidget(ArtistCard(artist: artist));

    expect(find.byType(ArtistThumbnail), findsOneWidget);
    expect(find.text('Banana'), findsOneWidget);

    await expectLater(
      find.byType(ArtistCard),
      matchesGoldenFile('goldens/artist_card.png'),
    );
  });

  testWidgets('goes to Artist Details screen', (WidgetTester tester) async {
    MockAppRouter router = MockAppRouter();
    when(
      router.gotoArtistDetailsScreen(any, artist: artist),
    ).thenAnswer((_) async => null);

    await tester.pumpAppWidget(ArtistCard(artist: artist, router: router));

    await tester.tap(find.text('Banana'));
    verify(router.gotoArtistDetailsScreen(any, artist: artist)).called(1);
  });
}

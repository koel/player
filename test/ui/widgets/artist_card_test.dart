import 'package:app/models/artist.dart';
import 'package:app/providers/artist_provider.dart';
import 'package:app/router.dart';
import 'package:app/ui/widgets/artist_card.dart';
import 'package:app/ui/widgets/album_artist_thumbnail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../../extensions/widget_tester_extension.dart';
import 'artist_card_test.mocks.dart';

@GenerateMocks([AppRouter, ArtistProvider])
void main() {
  late Artist artist;

  setUpAll(() {
    artist = Artist.fake(name: 'Banana');
  });

  testWidgets('renders', (WidgetTester tester) async {
    await tester.pumpAppWidget(ArtistCard(artist: artist));

    expect(find.byType(AlbumArtistThumbnail), findsOneWidget);
    expect(find.text('Banana'), findsOneWidget);
  });

  testWidgets('goes to Artist Details screen', (WidgetTester tester) async {
    MockAppRouter router = MockAppRouter();
    when(
      router.gotoArtistDetailsScreen(any, artistId: artist.id),
    ).thenAnswer((_) async => null);

    await tester.pumpAppWidget(ArtistCard(artist: artist, router: router));

    await tester.tap(find.text('Banana'));
    verify(router.gotoArtistDetailsScreen(any, artistId: artist.id)).called(1);
  });

  group('long-press context menu', () {
    Future<void> mountWithProvider(WidgetTester tester, Artist artist) async {
      await tester.pumpAppWidget(
        ChangeNotifierProvider<ArtistProvider>.value(
          value: MockArtistProvider(),
          child: ArtistCard(artist: artist),
        ),
      );
    }

    testWidgets('shows Edit when canEdit', (tester) async {
      final editable = Artist.fake(name: 'Editable', canEdit: true);
      await mountWithProvider(tester, editable);

      await tester.longPress(find.byType(ArtistCard));
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
    });

    testWidgets('no menu when canEdit is false', (tester) async {
      final readonly = Artist.fake(name: 'Read-only');
      await mountWithProvider(tester, readonly);

      await tester.longPress(find.byType(ArtistCard));
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsNothing);
    });
  });
}

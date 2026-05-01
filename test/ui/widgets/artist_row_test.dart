import 'package:app/models/artist.dart';
import 'package:app/providers/artist_provider.dart';
import 'package:app/ui/screens/artists.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../extensions/widget_tester_extension.dart';
import 'artist_card_test.mocks.dart';

void main() {
  Future<void> mountWithProvider(WidgetTester tester, Artist artist) async {
    await tester.pumpAppWidget(
      ChangeNotifierProvider<ArtistProvider>.value(
        value: MockArtistProvider(),
        child: ArtistRow(artist: artist, router: MockAppRouter()),
      ),
    );
  }

  testWidgets('shows Edit on long-press when canEdit', (tester) async {
    final artist = Artist.fake(name: 'Editable', canEdit: true);
    await mountWithProvider(tester, artist);

    await tester.longPress(find.byType(ArtistRow));
    await tester.pumpAndSettle();

    expect(find.text('Edit'), findsOneWidget);
  });

  testWidgets('no menu on long-press when canEdit is false', (tester) async {
    final artist = Artist.fake(name: 'Read-only');
    await mountWithProvider(tester, artist);

    await tester.longPress(find.byType(ArtistRow));
    await tester.pumpAndSettle();

    expect(find.text('Edit'), findsNothing);
  });
}

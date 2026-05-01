import 'package:app/models/album.dart';
import 'package:app/providers/album_provider.dart';
import 'package:app/ui/screens/albums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../extensions/widget_tester_extension.dart';
import 'album_card_test.mocks.dart';

void main() {
  Future<void> mountWithProvider(WidgetTester tester, Album album) async {
    await tester.pumpAppWidget(
      ChangeNotifierProvider<AlbumProvider>.value(
        value: MockAlbumProvider(),
        child: AlbumRow(
          album: album,
          router: MockAppRouter(),
        ),
      ),
    );
  }

  testWidgets('shows Edit on long-press when canEdit', (tester) async {
    final album = Album.fake(name: 'Editable', canEdit: true);
    await mountWithProvider(tester, album);

    await tester.longPress(find.byType(AlbumRow));
    await tester.pumpAndSettle();

    expect(find.text('Edit'), findsOneWidget);
  });

  testWidgets('no menu on long-press when canEdit is false', (tester) async {
    final album = Album.fake(name: 'Read-only');
    await mountWithProvider(tester, album);

    await tester.longPress(find.byType(AlbumRow));
    await tester.pumpAndSettle();

    expect(find.text('Edit'), findsNothing);
  });
}

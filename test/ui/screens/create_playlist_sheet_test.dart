import 'package:app/models/playlist.dart';
import 'package:app/providers/playlist_provider.dart';
import 'package:app/ui/screens/create_playlist_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../../extensions/widget_tester_extension.dart';
import '../widgets/playlist_row_test.mocks.dart';

@GenerateMocks([PlaylistProvider])
void main() {
  late MockPlaylistProvider playlistProviderMock;

  setUp(() {
    playlistProviderMock = MockPlaylistProvider();
  });

  Future<void> _mount(WidgetTester tester) async {
    await tester.pumpAppWidget(
      ChangeNotifierProvider<PlaylistProvider>.value(
        value: playlistProviderMock,
        child: CreatePlaylistSheet(),
      ),
    );
  }

  testWidgets('renders', (WidgetTester tester) async {
    await _mount(tester);
    await tester.enterText(
      find.byKey(CreatePlaylistSheet.nameFieldKey),
      'Best Bananas',
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(CreatePlaylistSheet),
      matchesGoldenFile('goldens/create_playlist_sheet.png'),
    );
  });

  testWidgets('creates a playlist successfully', (WidgetTester tester) async {
    when(playlistProviderMock.create(name: 'Best Bananas'))
        .thenAnswer((value) async => Playlist.fake());

    await _mount(tester);
    await tester.enterText(
      find.byKey(CreatePlaylistSheet.nameFieldKey),
      'Best Bananas',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CreatePlaylistSheet.submitButtonKey));
    await tester.pumpAndSettle(
      const Duration(seconds: 3), // fast forwarding the overlay timer
    );

    verify(playlistProviderMock.create(name: 'Best Bananas')).called(1);
  });

  testWidgets('creating a playlist fails', (WidgetTester tester) async {
    when(playlistProviderMock.create(name: 'Best Bananas')).thenThrow(Error());

    await _mount(tester);
    await tester.enterText(
      find.byKey(CreatePlaylistSheet.nameFieldKey),
      'Best Bananas',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CreatePlaylistSheet.submitButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoAlertDialog), findsOneWidget);
  });
}

import 'package:app/models/album.dart';
import 'package:app/models/artist.dart';
import 'package:app/providers/album_provider.dart';
import 'package:app/providers/playable_provider.dart';
import 'package:app/ui/screens/album_action_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';

import '../../extensions/widget_tester_extension.dart';
import 'album_action_sheet_test.mocks.dart';

@GenerateMocks([AlbumProvider, PlayableProvider])
void main() {
  Future<void> mount(WidgetTester tester, Album album) async {
    await tester.pumpAppWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AlbumProvider>.value(
            value: MockAlbumProvider(),
          ),
          ChangeNotifierProvider<PlayableProvider>.value(
            value: MockPlayableProvider(),
          ),
        ],
        child: AlbumActionSheet(album: album),
      ),
    );
  }

  testWidgets('renders album name and artist name', (tester) async {
    final album = Album.fake(
      name: 'Abbey Road',
      artist: Artist.fake(name: 'The Beatles'),
    );

    await mount(tester, album);

    expect(find.text('Abbey Road'), findsOneWidget);
    expect(find.text('The Beatles'), findsOneWidget);
  });

  testWidgets('renders the three quick actions', (tester) async {
    await mount(tester, Album.fake(name: 'A'));

    expect(find.text('Favorite'), findsOneWidget);
    expect(find.text('Play All'), findsOneWidget);
    expect(find.text('Shuffle All'), findsOneWidget);
  });

  testWidgets('shows "Undo Favorite" when album.favorite is true',
      (tester) async {
    await mount(tester, Album.fake(name: 'Loved', favorite: true));

    expect(find.text('Undo Favorite'), findsOneWidget);
    expect(find.text('Favorite'), findsNothing);
  });

  testWidgets('shows Edit only when canEdit is true', (tester) async {
    await mount(tester, Album.fake(name: 'Editable', canEdit: true));
    expect(find.text('Edit…'), findsOneWidget);
  });

  testWidgets('hides Edit when canEdit is false', (tester) async {
    await mount(tester, Album.fake(name: 'Read-only'));
    expect(find.text('Edit…'), findsNothing);
  });

  testWidgets('hides Go to Artist for Unknown Artist albums',
      (tester) async {
    final album = Album.fake(
      name: 'Mystery',
      artist: Artist.fake(name: 'Unknown Artist'),
    );

    await mount(tester, album);
    expect(find.text('Go to Artist'), findsNothing);
  });

  testWidgets('hides Go to Artist for Various Artists albums',
      (tester) async {
    final album = Album.fake(
      name: 'Compilation',
      artist: Artist.fake(name: 'Various Artists'),
    );

    await mount(tester, album);
    expect(find.text('Go to Artist'), findsNothing);
  });

  testWidgets('shows Go to Artist for a normal artist', (tester) async {
    final album = Album.fake(
      name: 'Real',
      artist: Artist.fake(name: 'Pink Floyd'),
    );

    await mount(tester, album);
    expect(find.text('Go to Artist'), findsOneWidget);
  });
}

import 'package:app/models/playlist.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/playlist_provider.dart';
import 'package:app/ui/widgets/playlist_row.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';

import '../../extensions/widget_tester_extension.dart';
import 'playlist_row_test.mocks.dart';

@GenerateMocks([PlaylistProvider])
void main() {
  late MockPlaylistProvider playlistProviderMock;
  late Playlist playlist;

  setUp(() {
    playlistProviderMock = MockPlaylistProvider();

    playlist = Playlist.fake(name: 'A Bunch of Bananas');
  });

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpAppWidget(
      ChangeNotifierProvider<PlaylistProvider>.value(
        value: playlistProviderMock,
        child: PlaylistRow(playlist: playlist),
      ),
    );
  }

  testWidgets('renders default state', (WidgetTester tester) async {
    await mount(tester);
    await tester.pumpAndSettle();

    expect(find.text('A Bunch of Bananas'), findsOneWidget);
    expect(find.text('Standard playlist'), findsOneWidget);
    expect(
      find.widgetWithIcon(ListTile, CupertinoIcons.music_note_list),
      findsOneWidget,
    );
  });

  testWidgets(
    'updates state when playlist is loaded',
    (WidgetTester tester) async {
      Playlist populatedPlaylist = Playlist.fake(
        id: playlist.id,
        name: playlist.name,
        isSmart: playlist.isSmart,
      );

      populatedPlaylist.songs = Song.fakeMany(4);

      await mount(tester);
      await tester.pumpAndSettle();
      expect(find.text('Standard playlist • 4 songs'), findsOneWidget);

      // The default icon should now be replaced by an image
      expect(
        find.widgetWithIcon(ListTile, CupertinoIcons.music_note_list),
        findsNothing,
      );
      expect(find.byType(CachedNetworkImage), findsOneWidget);

      await expectLater(
        find.byType(PlaylistRow),
        matchesGoldenFile('goldens/playlist_row_populated.png'),
      );
    },
  );
}

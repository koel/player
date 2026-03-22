import 'package:app/models/playlist.dart';
import 'package:app/providers/playlist_provider.dart';
import 'package:app/ui/widgets/playlist_row.dart';
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

  testWidgets('renders smart playlist', (WidgetTester tester) async {
    playlist = Playlist.fake(name: 'Smart Mix', isSmart: true);

    await tester.pumpAppWidget(
      ChangeNotifierProvider<PlaylistProvider>.value(
        value: playlistProviderMock,
        child: PlaylistRow(playlist: playlist),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Smart Mix'), findsOneWidget);
    expect(find.text('Smart playlist'), findsOneWidget);
  });
}

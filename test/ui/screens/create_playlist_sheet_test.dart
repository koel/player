import 'package:app/models/playlist.dart';
import 'package:app/providers/playlist_folder_provider.dart';
import 'package:app/providers/playlist_provider.dart';
import 'package:app/ui/screens/create_playlist_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'create_playlist_sheet_test.mocks.dart';

@GenerateMocks([PlaylistProvider, PlaylistFolderProvider])
void main() {
  late MockPlaylistProvider playlistProviderMock;
  late MockPlaylistFolderProvider folderProviderMock;

  setUp(() {
    playlistProviderMock = MockPlaylistProvider();
    folderProviderMock = MockPlaylistFolderProvider();
    when(folderProviderMock.folders).thenReturn([]);
  });

  Widget buildTestApp({required Widget child}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PlaylistProvider>.value(
          value: playlistProviderMock,
        ),
        ChangeNotifierProvider<PlaylistFolderProvider>.value(
          value: folderProviderMock,
        ),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('shows create playlist dialog', (tester) async {
    await tester.pumpWidget(buildTestApp(
      child: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showCreatePlaylistDialog(context),
          child: const Text('Open'),
        ),
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('New Playlist'), findsOneWidget);
    expect(find.text('Playlist Name'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
  });

  testWidgets('creates a playlist via dialog', (tester) async {
    when(playlistProviderMock.create(
      name: 'Best Bananas',
      description: '',
      folderId: null,
    )).thenAnswer((_) async => Playlist.fake());

    await tester.pumpWidget(buildTestApp(
      child: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showCreatePlaylistDialog(context),
          child: const Text('Open'),
        ),
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(CupertinoTextField).first,
      'Best Bananas',
    );
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    verify(playlistProviderMock.create(
      name: 'Best Bananas',
      description: '',
      folderId: null,
    )).called(1);
  });

  testWidgets('cancel closes dialog without creating', (tester) async {
    await tester.pumpWidget(buildTestApp(
      child: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showCreatePlaylistDialog(context),
          child: const Text('Open'),
        ),
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('New Playlist'), findsNothing);
    verifyNever(playlistProviderMock.create(name: anyNamed('name')));
  });
}

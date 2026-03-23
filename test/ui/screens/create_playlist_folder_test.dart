import 'package:app/models/playlist_folder.dart';
import 'package:app/providers/playlist_folder_provider.dart';
import 'package:app/ui/screens/create_playlist_folder_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'create_playlist_folder_test.mocks.dart';

@GenerateMocks([PlaylistFolderProvider])
void main() {
  late MockPlaylistFolderProvider folderProviderMock;

  setUp(() {
    folderProviderMock = MockPlaylistFolderProvider();
  });

  Widget buildTestApp() {
    return ChangeNotifierProvider<PlaylistFolderProvider>.value(
      value: folderProviderMock,
      child: MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showCreatePlaylistFolderDialog(context),
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  testWidgets('shows create folder dialog', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('New Folder'), findsOneWidget);
    expect(find.text('Enter a name for this folder.'), findsOneWidget);
    expect(find.text('Folder Name'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
  });

  testWidgets('creates a folder successfully', (tester) async {
    when(folderProviderMock.create(name: 'My Folder'))
        .thenAnswer((_) async => PlaylistFolder.fake(name: 'My Folder'));

    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(CupertinoTextField), 'My Folder');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    verify(folderProviderMock.create(name: 'My Folder')).called(1);
  });

  testWidgets('does not create with empty name', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    // Dialog should still be open
    expect(find.text('New Folder'), findsOneWidget);
    verifyNever(folderProviderMock.create(name: anyNamed('name')));
  });

  testWidgets('cancel closes dialog without creating', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('New Folder'), findsNothing);
    verifyNever(folderProviderMock.create(name: anyNamed('name')));
  });
}

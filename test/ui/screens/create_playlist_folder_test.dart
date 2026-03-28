import 'package:app/models/playlist_folder.dart';
import 'package:app/providers/playlist_folder_provider.dart';
import 'package:app/ui/screens/create_playlist_folder_sheet.dart';
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
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showCreatePlaylistFolderDialog(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows create folder sheet', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('New Folder'), findsOneWidget);
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

    await tester.enterText(find.byType(TextField), 'My Folder');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    verify(folderProviderMock.create(name: 'My Folder')).called(1);
  });

  testWidgets('cancel closes sheet without creating', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('New Folder'), findsNothing);
    verifyNever(folderProviderMock.create(name: anyNamed('name')));
  });
}

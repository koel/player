import 'package:app/models/song.dart';
import 'package:app/providers/favorite_provider.dart';
import 'package:app/providers/interaction_provider.dart';
import 'package:app/providers/playable_provider.dart';
import 'package:app/ui/widgets/now_playing/favorite_button.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../../../extensions/widget_tester_extension.dart';
import '../../../helpers/api_test_setup.dart';
import 'favorite_button_test.mocks.dart';

@GenerateMocks([InteractionProvider, PlayableProvider])
void main() {
  late MockInteractionProvider interactionProviderMock;
  late MockPlayableProvider playableProviderMock;

  setUpAll(() async => await initApiTestEnvironment());

  setUp(() {
    interactionProviderMock = MockInteractionProvider();
    playableProviderMock = MockPlayableProvider();
    when(playableProviderMock.syncWithVault(any))
        .thenAnswer((invocation) => invocation.positionalArguments.first);
    setUpApiTest();
  });

  tearDown(tearDownApiTest);

  Widget _button(Song song, FavoriteProvider favoriteProvider) => MultiProvider(
        providers: [
          ChangeNotifierProvider<InteractionProvider>.value(
            value: interactionProviderMock,
          ),
          ChangeNotifierProvider<FavoriteProvider>.value(
            value: favoriteProvider,
          ),
        ],
        child: FavoriteButton(song: song, inactiveColor: Colors.white54),
      );

  testWidgets('shows a hollow star when the song is not liked',
      (tester) async {
    final song = Song.fake(liked: false);
    await tester.pumpAppWidget(
      _button(song, FavoriteProvider(playableProvider: playableProviderMock)),
    );

    expect(find.byIcon(CupertinoIcons.star), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.star_fill), findsNothing);
  });

  testWidgets('shows a filled star when the song is liked', (tester) async {
    final song = Song.fake(liked: true);
    await tester.pumpAppWidget(
      _button(song, FavoriteProvider(playableProvider: playableProviderMock)),
    );

    expect(find.byIcon(CupertinoIcons.star_fill), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.star), findsNothing);
  });

  testWidgets('tapping delegates to InteractionProvider.toggleLike',
      (tester) async {
    final song = Song.fake(liked: false);
    when(interactionProviderMock.toggleLike(song: song))
        .thenAnswer((_) async {});

    await tester.pumpAppWidget(
      _button(song, FavoriteProvider(playableProvider: playableProviderMock)),
    );
    await tester.tap(find.byType(IconButton));
    await tester.pump();

    verify(interactionProviderMock.toggleLike(song: song)).called(1);
  });

  testWidgets(
    'reacts to a like toggled elsewhere via FavoriteProvider',
    (tester) async {
      final song = Song.fake(liked: false);
      final favoriteProvider =
          FavoriteProvider(playableProvider: playableProviderMock);
      final capturingClient = CapturingClient()..willReturn(json: {});
      capturingClient.install();

      await tester.pumpAppWidget(_button(song, favoriteProvider));
      expect(find.byIcon(CupertinoIcons.star), findsOneWidget);

      await favoriteProvider.toggleOne(playable: song);
      await tester.pump();

      expect(find.byIcon(CupertinoIcons.star_fill), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.star), findsNothing);
    },
  );
}

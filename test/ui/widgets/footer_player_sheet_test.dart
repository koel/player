import 'package:app/extensions/assets_audio_player.dart';
import 'package:app/models/artist.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/audio_provider.dart';
import 'package:app/providers/song_provider.dart';
import 'package:app/router.dart';
import 'package:app/ui/widgets/footer_player_sheet.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

import '../../extensions/widget_tester_extension.dart';
import 'footer_player_sheet_test.mocks.dart';

@GenerateMocks([AudioProvider, SongProvider, AppRouter])
void main() {
  late MockAudioProvider audioMock;
  late MockSongProvider songProviderMock;
  late MockAppRouter routerMock;
  late AssetsAudioPlayer player;
  late Song song;

  setUp(() {
    song = Song.fake(
      title: 'A Banana Work Is Never Done',
      artist: Artist.fake(name: 'Super Bananas'),
    );

    player = AssetsAudioPlayer();
    player.setSongId(song.id);

    audioMock = MockAudioProvider();
    when(audioMock.player).thenReturn(player);

    songProviderMock = MockSongProvider();
    when(songProviderMock.byId(song.id)).thenReturn(song);

    routerMock = MockAppRouter();
  });

  testWidgets('renders and functions with a song', (WidgetTester tester) async {
    final BehaviorSubject<PlayerState> playState =
        BehaviorSubject<PlayerState>.seeded(PlayerState.play);

    when(audioMock.playerState).thenAnswer((_) => playState);
    when(audioMock.playOrPause()).thenAnswer((_) async => null);
    when(audioMock.playNext()).thenAnswer((_) async => true);

    await tester.pumpAppWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AudioProvider>(create: (_) => audioMock),
          Provider<SongProvider>(create: (_) => songProviderMock),
        ],
        child: FooterPlayerSheet(router: routerMock),
      ),
    );

    await tester.pump();

    var title = find.text('A Banana Work Is Never Done');
    var pauseButton = find.byKey(FooterPlayerSheet.pauseButtonKey);
    var nextButton = find.byKey(FooterPlayerSheet.nextButtonKey);

    expect(title, findsOneWidget);
    expect(pauseButton, findsOneWidget);
    expect(nextButton, findsOneWidget);

    await expectLater(
      find.byType(FooterPlayerSheet),
      matchesGoldenFile('goldens/footer_player_sheet.png'),
    );

    await tester.tap(pauseButton);
    verify(audioMock.playOrPause()).called(1);

    await tester.tap(nextButton);
    verify(audioMock.playNext()).called(1);

    await tester.tap(title);
    verify(routerMock.openNowPlayingScreen(any)).called(1);
  });
}

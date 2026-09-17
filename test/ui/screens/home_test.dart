import 'package:app/models/album.dart';
import 'package:app/models/user.dart';
import 'package:app/providers/album_provider.dart';
import 'package:app/providers/auth_provider.dart';
import 'package:app/providers/overview_provider.dart';
import 'package:app/providers/recently_played_provider.dart';
import 'package:app/ui/screens/home.dart';
import 'package:app/ui/screens/profile_action_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../../extensions/widget_tester_extension.dart';
import '../../helpers/api_test_setup.dart';
import 'home_test.mocks.dart';

@GenerateMocks([AuthProvider, OverviewProvider, RecentlyPlayedProvider])
void main() {
  late MockAuthProvider authProviderMock;
  late MockOverviewProvider overviewProviderMock;
  late MockRecentlyPlayedProvider recentlyPlayedProviderMock;
  late AlbumProvider albumProvider;
  User? currentUser;

  final user = User(id: 'user-1', name: 'Jane', email: 'jane@koel.test');

  setUpAll(initApiTestEnvironment);

  setUp(() {
    setUpApiTest();

    authProviderMock = MockAuthProvider();
    overviewProviderMock = MockOverviewProvider();
    recentlyPlayedProviderMock = MockRecentlyPlayedProvider();
    albumProvider = AlbumProvider();
    addTearDown(albumProvider.dispose);
    currentUser = user;

    when(overviewProviderMock.isEmpty).thenReturn(false);
    when(overviewProviderMock.mostPlayedSongs).thenReturn([]);
    when(overviewProviderMock.recentlyAddedSongs).thenReturn([]);
    when(overviewProviderMock.recentlyPlayedSongs).thenReturn([]);
    when(overviewProviderMock.leastPlayedSongs).thenReturn([]);
    when(overviewProviderMock.randomSongs).thenReturn([]);
    when(overviewProviderMock.similarSongs).thenReturn([]);
    when(overviewProviderMock.mostPlayedAlbums)
        .thenReturn(albumProvider.syncWithVault([Album.fake(name: 'Top')]));
    when(overviewProviderMock.recentlyAddedAlbums)
        .thenReturn(albumProvider.syncWithVault([Album.fake(name: 'Latest')]));
    when(overviewProviderMock.randomAlbums).thenReturn([]);
    when(overviewProviderMock.mostPlayedArtists).thenReturn([]);
    when(overviewProviderMock.recentlyAddedArtists).thenReturn([]);
    when(overviewProviderMock.randomArtists).thenReturn([]);
    final overviewListeners = <VoidCallback>[];
    when(overviewProviderMock.addListener(any)).thenAnswer((invocation) =>
        overviewListeners.add(invocation.positionalArguments.single));
    when(overviewProviderMock.refresh()).thenAnswer(
      (_) => Future.microtask(() {
        for (final listener in overviewListeners) {
          listener();
        }
      }),
    );
    when(recentlyPlayedProviderMock.playables).thenReturn([]);
    when(authProviderMock.authUser).thenAnswer((_) => currentUser!);
    when(authProviderMock.maybeAuthUser).thenAnswer((_) => currentUser);
    when(authProviderMock.refreshAuthUser()).thenAnswer((_) async => user);
  });

  tearDown(tearDownApiTest);

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpAppWidget(
      MultiProvider(
        providers: [
          Provider<AuthProvider>.value(value: authProviderMock),
          ChangeNotifierProvider<OverviewProvider>.value(
            value: overviewProviderMock,
          ),
          ChangeNotifierProvider<RecentlyPlayedProvider>.value(
            value: recentlyPlayedProviderMock,
          ),
          ChangeNotifierProvider<AlbumProvider>.value(value: albumProvider),
        ],
        child: const HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pullToRefresh(WidgetTester tester) async {
    await tester.fling(find.text('Home'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
  }

  bool isAbove(WidgetTester tester, String upperText, String lowerText) =>
      tester.getTopLeft(find.text(upperText)).dy <
      tester.getTopLeft(find.text(lowerText)).dy;

  testWidgets('pulling to refresh applies the block order saved on the web',
      (tester) async {
    final reorderedUser = User(
      id: 'user-1',
      name: 'Jane',
      email: 'jane@koel.test',
      homeBlocksOrder: ['most-played-albums'],
    );
    when(authProviderMock.refreshAuthUser()).thenAnswer((_) async {
      currentUser = reorderedUser;
      return reorderedUser;
    });

    await mount(tester);
    expect(isAbove(tester, 'Latest Albums', 'Top Albums'), isTrue);

    await pullToRefresh(tester);

    expect(isAbove(tester, 'Top Albums', 'Latest Albums'), isTrue);
  });

  testWidgets(
      'pulling to refresh still reloads the overview when the user reload fails',
      (tester) async {
    when(authProviderMock.refreshAuthUser())
        .thenAnswer((_) async => throw Exception('offline'));

    await mount(tester);
    clearInteractions(overviewProviderMock);

    await pullToRefresh(tester);

    verify(overviewProviderMock.refresh()).called(1);
  });

  testWidgets('tapping the profile button opens the profile sheet',
      (tester) async {
    await mount(tester);

    await tester.tap(find.byIcon(CupertinoIcons.person_alt_circle));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileActionSheet), findsOneWidget);
    expect(find.text('jane@koel.test'), findsOneWidget);
  });
}

import 'package:app/audio_handler.dart';
import 'package:app/main.dart' as app;
import 'package:app/models/user.dart';
import 'package:app/providers/auth_provider.dart';
import 'package:app/providers/download_provider.dart';
import 'package:app/ui/screens/login.dart';
import 'package:app/ui/screens/profile_action_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../../helpers/api_test_setup.dart';
import 'profile_action_sheet_test.mocks.dart';

@GenerateMocks([KoelAudioHandler, AuthProvider, DownloadProvider])
void main() {
  late MockKoelAudioHandler audioHandlerMock;
  late MockAuthProvider authProviderMock;
  late MockDownloadProvider downloadProviderMock;

  final user = User(
    id: 'user-1',
    name: 'Jane',
    email: 'jane@koel.test',
    avatarUrl: 'https://koel.test/img/avatars/jane.webp',
  );

  setUpAll(initApiTestEnvironment);

  setUp(() {
    setUpApiTest();

    audioHandlerMock = MockKoelAudioHandler();
    authProviderMock = MockAuthProvider();
    downloadProviderMock = MockDownloadProvider();

    when(audioHandlerMock.cleanUpUponLogout()).thenAnswer((_) async {});
    when(authProviderMock.logout()).thenAnswer((_) async {});
    when(downloadProviderMock.clear()).thenAnswer((_) async {});

    app.audioHandler = audioHandlerMock;
  });

  tearDown(tearDownApiTest);

  Future<void> mount(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthProvider>.value(value: authProviderMock),
          Provider<DownloadProvider>.value(value: downloadProviderMock),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Material(
              child: TextButton(
                onPressed: () => showProfileActionSheet(context, user: user),
                child: const Text('Open sheet'),
              ),
            ),
          ),
          routes: {
            LoginScreen.routeName: (_) => const Text('LOGIN'),
          },
        ),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();
  }

  group('structure', () {
    testWidgets('renders the name, email and server', (tester) async {
      await mount(tester);

      expect(find.text('Jane'), findsOneWidget);
      expect(find.text('jane@koel.test'), findsOneWidget);
      expect(find.text('https://koel.test'), findsOneWidget);
    });

    testWidgets('sizes the avatar to the height of the account details',
        (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await mount(tester);

      final avatarSize = tester.getSize(find.descendant(
        of: find.byType(ProfileActionSheet),
        matching: find.byType(AspectRatio),
      ));
      final detailsHeight = tester
          .getSize(find
              .ancestor(
                of: find.text('Jane'),
                matching: find.byType(Column),
              )
              .first)
          .height;

      expect(avatarSize.height, detailsHeight);
      expect(avatarSize.width, avatarSize.height);
    });

    testWidgets('shows the avatar from the server', (tester) async {
      await mount(tester);

      final avatarImages = tester
          .widgetList<DecoratedBox>(find.descendant(
            of: find.byType(ProfileActionSheet),
            matching: find.byType(DecoratedBox),
          ))
          .map((box) => (box.decoration as BoxDecoration).image?.image)
          .whereType<CachedNetworkImageProvider>();

      expect(
        avatarImages.single.url,
        'https://koel.test/img/avatars/jane.webp',
      );
    });

    testWidgets('keeps the actions above the bottom inset', (tester) async {
      const bottomInset = 34.0;
      tester.view.padding = FakeViewPadding(
        bottom: bottomInset * tester.view.devicePixelRatio,
      );
      addTearDown(tester.view.resetPadding);

      await mount(tester);

      final logOutBottom =
          tester.getBottomLeft(find.widgetWithText(ListTile, 'Log Out')).dy;
      expect(logOutBottom, lessThanOrEqualTo(812 - bottomInset));
    });

    testWidgets('keeps room for the account details at 3x text size',
        (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await mount(tester);

      final avatarWidth = tester
          .getSize(find.descendant(
            of: find.byType(ProfileActionSheet),
            matching: find.byType(AspectRatio),
          ))
          .width;
      final detailsWidth = tester
          .getSize(find
              .ancestor(
                of: find.text('Jane'),
                matching: find.byType(Column),
              )
              .first)
          .width;

      expect(detailsWidth, greaterThanOrEqualTo(avatarWidth));
    });
  });

  group('actions', () {
    testWidgets('tapping Clear Downloads clears downloads and closes the sheet',
        (tester) async {
      await mount(tester);

      await tester.tap(find.text('Clear Downloads'));
      await tester.pumpAndSettle();

      verify(downloadProviderMock.clear()).called(1);
      expect(find.byType(ProfileActionSheet), findsNothing);
    });

    testWidgets('cancelling Log Out keeps the user logged in', (tester) async {
      await mount(tester);

      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();
      expect(find.text('Log out?'), findsOneWidget);

      await tester.tap(find.widgetWithText(CupertinoDialogAction, 'Cancel'));
      await tester.pumpAndSettle();

      verifyNever(authProviderMock.logout());
      expect(find.byType(ProfileActionSheet), findsOneWidget);
    });

    testWidgets('confirming Log Out logs out and returns to the login screen',
        (tester) async {
      await mount(tester);

      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CupertinoDialogAction, 'Confirm'));
      await tester.pumpAndSettle();

      verify(authProviderMock.logout()).called(1);
      verify(audioHandlerMock.cleanUpUponLogout()).called(1);
      expect(find.text('LOGIN'), findsOneWidget);
      expect(find.byType(ProfileActionSheet), findsNothing);
    });
  });
}

import 'package:app/exceptions/exceptions.dart';
import 'package:app/providers/auth_provider.dart';
import 'package:app/ui/screens/data_loading.dart';
import 'package:app/ui/screens/two_factor_challenge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../../extensions/widget_tester_extension.dart';
import '../../helpers/api_test_setup.dart';
import 'two_factor_challenge_test.mocks.dart';

@GenerateMocks([AuthProvider])
void main() {
  late MockAuthProvider authMock;

  setUpAll(() async => await initApiTestEnvironment());

  setUp(() {
    authMock = MockAuthProvider();
    setUpApiTest();
  });

  tearDown(tearDownApiTest);

  Future<void> _mount(WidgetTester tester) async {
    await tester.pumpAppWidget(
      Provider<AuthProvider>.value(
        value: authMock,
        child: const TwoFactorChallengeScreen(
          host: 'https://koel.test',
          email: 'user@koel.test',
          loginToken: 'lt-123',
        ),
      ),
      routes: {
        DataLoadingScreen.routeName: (_) => const Text('LOADING'),
      },
    );
  }

  testWidgets('verifies the entered code and continues on success',
      (tester) async {
    when(authMock.completeTwoFactorChallenge(
      loginToken: 'lt-123',
      code: '123456',
    )).thenAnswer((_) async {});
    when(authMock.tryGetAuthUser()).thenAnswer((_) async => null);

    await _mount(tester);
    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    verify(authMock.completeTwoFactorChallenge(
      loginToken: 'lt-123',
      code: '123456',
    )).called(1);
    expect(find.text('LOADING'), findsOneWidget);
  });

  testWidgets('shows an error for an invalid code and stays on the screen',
      (tester) async {
    when(authMock.completeTwoFactorChallenge(
      loginToken: anyNamed('loginToken'),
      code: anyNamed('code'),
    )).thenThrow(HttpResponseException(
      response: http.Response('nope', 401),
    ));

    await _mount(tester);
    await tester.enterText(find.byType(TextFormField), 'wrong');
    await tester.tap(find.text('Verify'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Invalid authentication code.'), findsOneWidget);
    expect(find.text('LOADING'), findsNothing);
    verifyNever(authMock.tryGetAuthUser());
  });
}

import 'package:app/providers/auth_provider.dart';
import 'package:app/ui/screens/login.dart';
import 'package:app/ui/widgets/oops_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../../extensions/widget_tester_extension.dart';
import '../../utils.dart';
import 'oops_box_test.mocks.dart';

@GenerateMocks([AuthProvider])
void main() {
  late MockAuthProvider authMock;
  late Widget dummyLoginScreen;

  setUp(() {
    authMock = MockAuthProvider();
    dummyLoginScreen = Text('Dummy Login Screen');
  });

  Future<void> _mount(
    WidgetTester tester, {
    void Function()? retryFunction,
    bool showLogOutButton = false,
  }) async {
    await tester.pumpAppWidget(
        Provider<AuthProvider>.value(
          value: authMock,
          child: OopsBox(
            onRetry: retryFunction,
            showLogOutButton: showLogOutButton,
          ),
        ),
        routes: {
          LoginScreen.routeName: (_) => dummyLoginScreen,
        });
  }

  testWidgets('renders', (WidgetTester tester) async {
    await _mount(tester, retryFunction: () {});

    expect(find.text('Oops!'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('invokes Retry function', (WidgetTester tester) async {
    var retry = Callable();
    await _mount(tester, retryFunction: retry);
    await tester.tap(find.byKey(OopsBox.retryButtonKey));
    expect(retry.called, isTrue);
  });

  testWidgets('logs out', (WidgetTester tester) async {
    when(authMock.logout()).thenAnswer((_) async {});
    await _mount(tester, showLogOutButton: true);
    await tester.tap(find.byKey(OopsBox.logOutButtonKey));
    await tester.pumpAndSettle();
    verify(authMock.logout()).called(1);
    expect(find.text('Dummy Login Screen'), findsOneWidget);
  });
}

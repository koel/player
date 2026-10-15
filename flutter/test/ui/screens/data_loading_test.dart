import 'dart:async';

import 'package:app/app_state.dart';
import 'package:app/enums.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/auth_provider.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/providers/download_provider.dart';
import 'package:app/ui/screens/data_loading.dart';
import 'package:app/ui/screens/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../../extensions/widget_tester_extension.dart';
import 'data_loading_test.mocks.dart';

@GenerateMocks([DataProvider, DownloadProvider, AuthProvider])
void main() {
  late MockDataProvider dataProvider;
  late MockDownloadProvider downloadProvider;
  late MockAuthProvider authProvider;
  late Completer<void> initCompleter;

  setUp(() {
    AppState.clear();
    dataProvider = MockDataProvider();
    downloadProvider = MockDownloadProvider();
    authProvider = MockAuthProvider();
    initCompleter = Completer<void>();
    when(dataProvider.init()).thenAnswer((_) => initCompleter.future);
  });

  Future<void> mount(
    WidgetTester tester, {
    List<Playable> downloads = const [],
  }) async {
    when(downloadProvider.playables).thenReturn(downloads);

    await tester.pumpAppWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DataProvider>.value(value: dataProvider),
          Provider<DownloadProvider>.value(value: downloadProvider),
          Provider<AuthProvider>.value(value: authProvider),
        ],
        child: const DataLoadingScreen(),
      ),
      routes: {MainScreen.routeName: (_) => const Text('MAIN')},
    );
    await tester.pump();
  }

  // Completes the still-hanging load so no timers outlive the test.
  Future<void> settle(WidgetTester tester) async {
    if (!initCompleter.isCompleted) initCompleter.complete();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('does not nag while the load is still fresh', (tester) async {
    await mount(tester);

    expect(find.text('This is taking longer than usual…'), findsNothing);

    await settle(tester);
  });

  testWidgets(
    'shows the still-loading message after a delay, without a downloads button',
    (tester) async {
      await mount(tester);
      await tester.pump(const Duration(seconds: 7));

      expect(find.text('This is taking longer than usual…'), findsOneWidget);
      expect(find.text('View Downloads'), findsNothing);

      await settle(tester);
    },
  );

  testWidgets(
    'offers View Downloads after a delay and enters offline mode',
    (tester) async {
      await mount(tester, downloads: [Song.fake()]);
      await tester.pump(const Duration(seconds: 7));

      expect(find.text('View Downloads'), findsOneWidget);

      await tester.tap(find.text('View Downloads'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('MAIN'), findsOneWidget);
      expect(AppState.get('mode'), AppMode.offline);

      await settle(tester);
    },
  );

  testWidgets('falls back to the error box after the load times out',
      (tester) async {
    await mount(tester);
    await tester.pump(const Duration(seconds: 30));

    expect(find.text('Oops!'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);

    await settle(tester);
  });

  testWidgets('shows the error box when the load fails', (tester) async {
    when(dataProvider.init()).thenAnswer((_) async => throw Exception('boom'));

    await mount(tester);

    expect(find.text('Oops!'), findsOneWidget);
  });

  testWidgets('a stale load cannot clobber a retry', (tester) async {
    await mount(tester);
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('Oops!'), findsOneWidget);

    // Retry with a fresh, still-pending load.
    final retryCompleter = Completer<void>();
    when(dataProvider.init()).thenAnswer((_) => retryCompleter.future);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.text('Oops!'), findsNothing);

    // The stale first attempt resolves late — it must be ignored.
    initCompleter.complete();
    await tester.pump();
    expect(find.text('MAIN'), findsNothing);

    // The retry attempt resolves — it navigates.
    retryCompleter.complete();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('MAIN'), findsOneWidget);
  });
}

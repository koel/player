import 'dart:async';

import 'package:app/app_state.dart';
import 'package:app/enums.dart';
import 'package:app/models/models.dart';
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

@GenerateMocks([DataProvider, DownloadProvider])
void main() {
  late MockDataProvider dataProvider;
  late MockDownloadProvider downloadProvider;
  late Completer<void> initCompleter;

  setUp(() {
    AppState.clear();
    dataProvider = MockDataProvider();
    downloadProvider = MockDownloadProvider();
    initCompleter = Completer<void>();
    when(dataProvider.init()).thenAnswer((_) => initCompleter.future);
  });

  Future<void> mount(
    WidgetTester tester, {
    required List<Playable> downloads,
  }) async {
    when(downloadProvider.playables).thenReturn(downloads);

    await tester.pumpAppWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DataProvider>.value(value: dataProvider),
          Provider<DownloadProvider>.value(value: downloadProvider),
        ],
        child: const DataLoadingScreen(),
      ),
      routes: {MainScreen.routeName: (_) => const Text('MAIN')},
    );
  }

  // Completes the still-hanging load so no timers outlive the test.
  Future<void> settle(WidgetTester tester) async {
    if (!initCompleter.isCompleted) initCompleter.complete();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('does not nag while the load is still fresh', (tester) async {
    await mount(tester, downloads: []);
    await tester.pump();

    expect(find.text('This is taking longer than usual…'), findsNothing);

    await settle(tester);
  });

  testWidgets(
    'shows the still-loading message after a delay, without a downloads button',
    (tester) async {
      await mount(tester, downloads: []);
      await tester.pump();
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
      await tester.pump();
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
}

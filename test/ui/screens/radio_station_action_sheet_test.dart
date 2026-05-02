import 'package:app/app_state.dart';
import 'package:app/models/radio_station.dart';
import 'package:app/providers/radio_player_provider.dart';
import 'package:app/providers/radio_station_provider.dart';
import 'package:app/ui/screens/radio_station_action_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:version/version.dart';

import '../../extensions/widget_tester_extension.dart';
import 'radio_station_action_sheet_test.mocks.dart';

@GenerateMocks([RadioStationProvider, RadioPlayerProvider])
void main() {
  late MockRadioStationProvider stationProviderMock;
  late MockRadioPlayerProvider radioPlayerMock;

  setUp(() {
    AppState.clear();
    AppState.set(['app', 'apiVersion'], Version.parse('7.11.0'));

    stationProviderMock = MockRadioStationProvider();
    radioPlayerMock = MockRadioPlayerProvider();

    // Default to "no current station, idle"; individual tests override.
    when(radioPlayerMock.currentStation).thenReturn(null);
    when(radioPlayerMock.playing).thenReturn(false);
    when(radioPlayerMock.loading).thenReturn(false);
  });

  Future<void> mount(WidgetTester tester, RadioStation station) async {
    await tester.pumpAppWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<RadioStationProvider>.value(
            value: stationProviderMock,
          ),
          ChangeNotifierProvider<RadioPlayerProvider>.value(
            value: radioPlayerMock,
          ),
        ],
        child: RadioStationActionSheet(station: station),
      ),
    );
  }

  group('structure', () {
    testWidgets('renders the station name', (tester) async {
      await mount(tester, RadioStation.fake(name: 'Jazz FM'));

      expect(find.text('Jazz FM'), findsOneWidget);
    });

    testWidgets('renders description when present', (tester) async {
      final station = RadioStation.fake(name: 'Jazz FM');
      station.description = 'Smooth jazz all day';
      await mount(tester, station);

      expect(find.text('Smooth jazz all day'), findsOneWidget);
    });

    testWidgets('renders Favorite + Play quick row by default',
        (tester) async {
      await mount(tester, RadioStation.fake(name: 'A'));

      expect(find.text('Favorite'), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);
      expect(find.text('Stop'), findsNothing);
    });

    testWidgets('shows "Undo Favorite" when station.favorite is true',
        (tester) async {
      await mount(tester, RadioStation.fake(name: 'Loved', favorite: true));

      expect(find.text('Undo Favorite'), findsOneWidget);
      expect(find.text('Favorite'), findsNothing);
    });

    testWidgets('hides Favorite when koel version is below 7.11.0',
        (tester) async {
      AppState.set(['app', 'apiVersion'], Version.parse('7.10.0'));

      await mount(tester, RadioStation.fake(name: 'A'));

      expect(find.text('Favorite'), findsNothing);
      expect(find.text('Undo Favorite'), findsNothing);
      // Play stays.
      expect(find.text('Play'), findsOneWidget);
    });

    testWidgets('shows Edit only when canEdit is true', (tester) async {
      await mount(tester, RadioStation.fake(name: 'Editable', canEdit: true));
      expect(find.text('Edit…'), findsOneWidget);
    });

    testWidgets('hides Edit when canEdit is false', (tester) async {
      await mount(tester, RadioStation.fake(name: 'Read-only'));
      expect(find.text('Edit…'), findsNothing);
    });

    testWidgets('shows Delete only when canDelete is true', (tester) async {
      await mount(
        tester,
        RadioStation.fake(name: 'Deletable', canDelete: true),
      );
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('hides Delete when canDelete is false', (tester) async {
      await mount(tester, RadioStation.fake(name: 'Read-only'));
      expect(find.text('Delete'), findsNothing);
    });
  });

  group('Play/Stop reactivity', () {
    testWidgets(
      'shows Stop when this station is the current playing station',
      (tester) async {
        final station = RadioStation.fake(id: 'me');
        when(radioPlayerMock.currentStation).thenReturn(station);
        when(radioPlayerMock.playing).thenReturn(true);

        await mount(tester, station);

        expect(find.text('Stop'), findsOneWidget);
        expect(find.text('Play'), findsNothing);
      },
    );

    testWidgets(
      'shows Stop when this station is the current loading station',
      (tester) async {
        final station = RadioStation.fake(id: 'me');
        when(radioPlayerMock.currentStation).thenReturn(station);
        when(radioPlayerMock.playing).thenReturn(false);
        when(radioPlayerMock.loading).thenReturn(true);

        await mount(tester, station);

        expect(find.text('Stop'), findsOneWidget);
      },
    );

    testWidgets(
      'shows Play when a *different* station is current',
      (tester) async {
        final me = RadioStation.fake(id: 'me');
        final other = RadioStation.fake(id: 'other');
        when(radioPlayerMock.currentStation).thenReturn(other);
        when(radioPlayerMock.playing).thenReturn(true);

        await mount(tester, me);

        expect(find.text('Play'), findsOneWidget);
        expect(find.text('Stop'), findsNothing);
      },
    );
  });

  group('actions', () {
    testWidgets(
      'tapping Favorite delegates to RadioStationProvider.toggleFavorite',
      (tester) async {
        final station = RadioStation.fake(name: 'Loved');
        when(stationProviderMock.toggleFavorite(station))
            .thenAnswer((_) async {});

        await mount(tester, station);
        await tester.tap(find.text('Favorite'));
        await tester.pump();

        verify(stationProviderMock.toggleFavorite(station)).called(1);
      },
    );

    testWidgets(
      'tapping Play delegates to RadioPlayerProvider.play',
      (tester) async {
        final station = RadioStation.fake(name: 'Jazz FM');
        when(radioPlayerMock.play(station)).thenAnswer((_) async {});

        await mount(tester, station);
        await tester.tap(find.text('Play'));
        await tester.pump();

        verify(radioPlayerMock.play(station)).called(1);
        verifyNever(radioPlayerMock.stop());
      },
    );

    testWidgets(
      'tapping Stop delegates to RadioPlayerProvider.stop',
      (tester) async {
        final station = RadioStation.fake(name: 'Jazz FM');
        when(radioPlayerMock.currentStation).thenReturn(station);
        when(radioPlayerMock.playing).thenReturn(true);
        when(radioPlayerMock.stop()).thenAnswer((_) async {});

        await mount(tester, station);
        await tester.tap(find.text('Stop'));
        await tester.pump();

        verify(radioPlayerMock.stop()).called(1);
        verifyNever(radioPlayerMock.play(any));
      },
    );
  });
}

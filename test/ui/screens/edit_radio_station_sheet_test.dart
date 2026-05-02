import 'package:app/models/radio_station.dart';
import 'package:app/providers/radio_player_provider.dart';
import 'package:app/providers/radio_station_provider.dart';
import 'package:app/ui/screens/edit_radio_station_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../../extensions/widget_tester_extension.dart';
import 'edit_radio_station_sheet_test.mocks.dart';

@GenerateMocks([RadioStationProvider, RadioPlayerProvider])
void main() {
  late MockRadioStationProvider stationProviderMock;
  late MockRadioPlayerProvider radioPlayerMock;

  setUp(() {
    stationProviderMock = MockRadioStationProvider();
    radioPlayerMock = MockRadioPlayerProvider();

    when(stationProviderMock.update(
      any,
      name: anyNamed('name'),
      url: anyNamed('url'),
      description: anyNamed('description'),
      isPublic: anyNamed('isPublic'),
    )).thenAnswer((_) async {});

    // Default: no station on air.
    when(radioPlayerMock.currentStation).thenReturn(null);
    when(radioPlayerMock.play(any)).thenAnswer((_) async {});
  });

  Future<void> openDialog(WidgetTester tester, RadioStation station) async {
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
        child: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () =>
                  showEditRadioStationDialog(context, station: station),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> typeIntoField(
    WidgetTester tester, {
    required String hint,
    required String text,
  }) async {
    final finder = find.widgetWithText(TextField, hint).first;
    await tester.enterText(finder, text);
  }

  group('live edit while station is playing', () {
    testWidgets(
      'changing the URL restarts the stream',
      (tester) async {
        final station = RadioStation(
          id: 's1',
          name: 'Jazz FM',
          url: 'https://old.example.com/live',
        );
        when(radioPlayerMock.currentStation).thenReturn(station);

        await openDialog(tester, station);
        await typeIntoField(
          tester,
          hint: 'Stream URL',
          text: 'https://new.example.com/live',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));

        verify(radioPlayerMock.play(station)).called(1);
        verifyNever(radioPlayerMock.refreshMediaItem());
      },
    );

    testWidgets(
      'changing only the name refreshes the media item without restart',
      (tester) async {
        final station = RadioStation(
          id: 's1',
          name: 'Jazz FM',
          url: 'https://example.com/live',
        );
        when(radioPlayerMock.currentStation).thenReturn(station);

        await openDialog(tester, station);
        await typeIntoField(tester, hint: 'Station Name', text: 'Smooth Jazz');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));

        verify(radioPlayerMock.refreshMediaItem()).called(1);
        verifyNever(radioPlayerMock.play(any));
      },
    );

    testWidgets(
      'changing only the description does nothing on the player',
      (tester) async {
        final station = RadioStation(
          id: 's1',
          name: 'Jazz FM',
          url: 'https://example.com/live',
          description: 'old',
        );
        when(radioPlayerMock.currentStation).thenReturn(station);

        await openDialog(tester, station);
        await typeIntoField(
          tester,
          hint: 'Description (optional)',
          text: 'new description',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));

        verifyNever(radioPlayerMock.play(any));
        verifyNever(radioPlayerMock.refreshMediaItem());
      },
    );

    testWidgets(
      'does nothing on the player when a different station is on air',
      (tester) async {
        final editing = RadioStation(
          id: 's1',
          name: 'Jazz FM',
          url: 'https://old.example.com/live',
        );
        final onAir = RadioStation.fake(id: 's2');
        when(radioPlayerMock.currentStation).thenReturn(onAir);

        await openDialog(tester, editing);
        await typeIntoField(
          tester,
          hint: 'Stream URL',
          text: 'https://new.example.com/live',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));

        verifyNever(radioPlayerMock.play(any));
        verifyNever(radioPlayerMock.refreshMediaItem());
      },
    );
  });
}

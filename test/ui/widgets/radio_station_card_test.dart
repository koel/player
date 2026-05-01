import 'package:app/models/radio_station.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/widgets/radio_station_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';

import '../../extensions/widget_tester_extension.dart';
import 'radio_station_card_test.mocks.dart';

@GenerateMocks([RadioStationProvider, RadioPlayerProvider])

void main() {
  testWidgets('renders station name', (WidgetTester tester) async {
    final station = RadioStation.fake(name: 'Jazz FM');

    await tester.pumpAppWidget(RadioStationCard(station: station));

    expect(find.text('Jazz FM'), findsOneWidget);
  });

  testWidgets('renders description when present', (WidgetTester tester) async {
    final station = RadioStation(
      id: 'station-1',
      name: 'Jazz FM',
      url: 'https://stream.example.com/live',
      description: 'The best jazz station',
    );

    await tester.pumpAppWidget(RadioStationCard(station: station));

    expect(find.text('Jazz FM'), findsOneWidget);
    expect(find.text('The best jazz station'), findsOneWidget);
  });

  testWidgets('does not render description when absent',
      (WidgetTester tester) async {
    final station = RadioStation.fake(name: 'Rock Radio');

    await tester.pumpAppWidget(RadioStationCard(station: station));

    expect(find.text('Rock Radio'), findsOneWidget);
    expect(find.byType(CachedNetworkImage), findsNothing);
  });

  testWidgets('uses CachedNetworkImage when logo is present',
      (WidgetTester tester) async {
    final station = RadioStation(
      id: 'station-1',
      name: 'Logo FM',
      url: 'https://stream.example.com/live',
      logo: 'https://example.com/logo.png',
    );

    await tester.pumpAppWidget(RadioStationCard(station: station));

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.imageUrl, 'https://example.com/logo.png');
  });

  testWidgets('shows default icon when no logo', (WidgetTester tester) async {
    final station = RadioStation.fake(name: 'No Logo FM');

    await tester.pumpAppWidget(RadioStationCard(station: station));

    expect(
      find.byIcon(CupertinoIcons.antenna_radiowaves_left_right),
      findsOneWidget,
    );
  });

  testWidgets('calls onTap when tapped', (WidgetTester tester) async {
    var tapped = false;
    final station = RadioStation.fake(name: 'Tap FM');

    await tester.pumpAppWidget(
      RadioStationCard(station: station, onTap: () => tapped = true),
    );

    await tester.tap(find.text('Tap FM'));
    expect(tapped, isTrue);
  });

  group('long-press context menu', () {
    Future<void> mountWithProviders(
      WidgetTester tester,
      RadioStation station,
    ) async {
      await tester.pumpAppWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<RadioStationProvider>.value(
              value: MockRadioStationProvider(),
            ),
            ChangeNotifierProvider<RadioPlayerProvider>.value(
              value: MockRadioPlayerProvider(),
            ),
          ],
          child: RadioStationCard(station: station, onTap: () {}),
        ),
      );
    }

    testWidgets('shows Edit when canEdit', (tester) async {
      final station = RadioStation.fake(name: 'Editable', canEdit: true);
      await mountWithProviders(tester, station);

      await tester.longPress(find.byType(RadioStationCard));
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('shows Delete when canDelete', (tester) async {
      final station = RadioStation.fake(name: 'Deletable', canDelete: true);
      await mountWithProviders(tester, station);

      await tester.longPress(find.byType(RadioStationCard));
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
    });

    testWidgets('shows both when both permissions granted', (tester) async {
      final station = RadioStation.fake(canEdit: true, canDelete: true);
      await mountWithProviders(tester, station);

      await tester.longPress(find.byType(RadioStationCard));
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('no menu when neither permission is granted', (tester) async {
      final station = RadioStation.fake();
      await mountWithProviders(tester, station);

      await tester.longPress(find.byType(RadioStationCard));
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsNothing);
      expect(find.text('Delete'), findsNothing);
    });
  });
}

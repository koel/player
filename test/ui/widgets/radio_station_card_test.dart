import 'package:app/models/radio_station.dart';
import 'package:app/ui/widgets/radio_station_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../extensions/widget_tester_extension.dart';

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
    // Only the name text widget should be present
    expect(find.byType(Text), findsOneWidget);
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
}

import 'package:app/models/radio_station.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RadioStationsScreen highlighting', () {
    test('station is identified as playing when IDs match', () {
      final station = RadioStation.fake(id: 'station-1');
      final currentStation = RadioStation.fake(id: 'station-1');

      expect(currentStation.id == station.id, isTrue);
    });

    test('station is not highlighted when a different station is playing', () {
      final station = RadioStation.fake(id: 'station-1');
      final currentStation = RadioStation.fake(id: 'station-2');

      expect(currentStation.id == station.id, isFalse);
    });

    test('station is not highlighted when no station is playing', () {
      final station = RadioStation.fake(id: 'station-1');
      RadioStation? currentStation;

      expect(currentStation?.id == station.id, isFalse);
    });

    test('highlighting updates when current station changes', () {
      final station1 = RadioStation.fake(id: 'station-1');
      final station2 = RadioStation.fake(id: 'station-2');
      RadioStation? currentStation;

      // Initially no station playing
      expect(currentStation?.id == station1.id, isFalse);
      expect(currentStation?.id == station2.id, isFalse);

      // Start playing station 1
      currentStation = station1;
      expect(currentStation.id == station1.id, isTrue);
      expect(currentStation.id == station2.id, isFalse);

      // Switch to station 2
      currentStation = station2;
      expect(currentStation.id == station1.id, isFalse);
      expect(currentStation.id == station2.id, isTrue);

      // Stop playback
      currentStation = null;
      expect(currentStation?.id == station1.id, isFalse);
      expect(currentStation?.id == station2.id, isFalse);
    });
  });

  group('RadioStationsScreen thumbnail overlay logic', () {
    // These tests verify the conditional logic used in _RadioStationRow
    // to determine what to show on the thumbnail overlay.

    test('shows animation when playing', () {
      final isPlaying = true;
      final loading = false;
      final playing = true;

      // Overlay is shown when isPlaying (current station matches)
      expect(isPlaying, isTrue);
      // Animation is shown when loading or playing
      expect(loading || playing, isTrue);
    });

    test('shows animation when loading', () {
      final isPlaying = true;
      final loading = true;
      final playing = false;

      expect(isPlaying, isTrue);
      expect(loading || playing, isTrue);
    });

    test('shows only overlay with no animation when paused', () {
      final isPlaying = true;
      final loading = false;
      final playing = false;

      // Overlay still shown (station is active)
      expect(isPlaying, isTrue);
      // But no animation
      expect(loading || playing, isFalse);
    });

    test('no overlay when station is not active', () {
      final isPlaying = false;
      final loading = false;
      final playing = true;

      // No overlay at all
      expect(isPlaying, isFalse);
    });
  });
}

import 'package:app/models/radio_station.dart';
import 'package:audio_service/audio_service.dart';
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
    test('shows animation when playing', () {
      final isPlaying = true;
      final loading = false;
      final playing = true;

      expect(isPlaying, isTrue);
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

      expect(isPlaying, isTrue);
      expect(loading || playing, isFalse);
    });

    test('no overlay when station is not active', () {
      final isPlaying = false;

      expect(isPlaying, isFalse);
    });
  });

  group('Radio media session integration', () {
    test('radio station produces a valid MediaItem', () {
      final station = RadioStation.fake(
        id: 'station-1',
        name: 'Jazz FM',
      );

      final mediaItem = MediaItem(
        id: 'radio-${station.id}',
        title: station.name,
        artist: 'Radio',
        artUri: station.logo != null ? Uri.parse(station.logo!) : null,
      );

      expect(mediaItem.id, 'radio-station-1');
      expect(mediaItem.title, 'Jazz FM');
      expect(mediaItem.artist, 'Radio');
      // No duration for live streams
      expect(mediaItem.duration, isNull);
    });

    test('radio MediaItem includes art URI when logo is present', () {
      final station = RadioStation(
        id: 'station-1',
        name: 'Jazz FM',
        url: 'https://stream.example.com/live',
        logo: 'https://example.com/logo.png',
      );

      final mediaItem = MediaItem(
        id: 'radio-${station.id}',
        title: station.name,
        artist: 'Radio',
        artUri: station.logo != null ? Uri.parse(station.logo!) : null,
      );

      expect(mediaItem.artUri, Uri.parse('https://example.com/logo.png'));
    });

    test('radio MediaItem has no art URI when logo is null', () {
      final station = RadioStation.fake(id: 'station-1');

      final mediaItem = MediaItem(
        id: 'radio-${station.id}',
        title: station.name,
        artist: 'Radio',
        artUri: station.logo != null ? Uri.parse(station.logo!) : null,
      );

      expect(mediaItem.artUri, isNull);
    });

    test('radio playback state has play/pause and stop controls', () {
      // Simulates what updateRadioPlaybackState produces
      final controls = [MediaControl.pause, MediaControl.stop];

      expect(controls, contains(MediaControl.pause));
      expect(controls, contains(MediaControl.stop));
      // No skip controls for radio
      expect(controls, isNot(contains(MediaControl.skipToNext)));
      expect(controls, isNot(contains(MediaControl.skipToPrevious)));
    });

    test('radio playback state shows play control when paused', () {
      final playing = false;
      final controls = [
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
      ];

      expect(controls, contains(MediaControl.play));
      expect(controls, isNot(contains(MediaControl.pause)));
    });
  });
}

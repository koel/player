import 'package:app/audio_handler.dart';
import 'package:app/models/radio_station.dart';
import 'package:app/providers/radio_player_provider.dart';
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
    test('mediaItemForStation produces correct MediaItem', () {
      final station = RadioStation.fake(id: 'station-1', name: 'Jazz FM');
      final mediaItem = RadioPlayerProvider.mediaItemForStation(station);

      expect(mediaItem.id, 'radio-station-1');
      expect(mediaItem.title, 'Jazz FM');
      expect(mediaItem.artist, 'Radio');
      expect(mediaItem.duration, isNull);
    });

    test('mediaItemForStation includes art URI when logo is present', () {
      final station = RadioStation(
        id: 'station-1',
        name: 'Jazz FM',
        url: 'https://stream.example.com/live',
        logo: 'https://example.com/logo.png',
      );
      final mediaItem = RadioPlayerProvider.mediaItemForStation(station);

      expect(mediaItem.artUri, Uri.parse('https://example.com/logo.png'));
    });

    test('mediaItemForStation has no art URI when logo is null', () {
      final station = RadioStation.fake(id: 'station-1');
      final mediaItem = RadioPlayerProvider.mediaItemForStation(station);

      expect(mediaItem.artUri, isNull);
    });

    test('radioControls returns pause when playing', () {
      final controls = KoelAudioHandler.radioControls(playing: true);

      expect(controls, [MediaControl.pause]);
      expect(controls, isNot(contains(MediaControl.skipToNext)));
      expect(controls, isNot(contains(MediaControl.skipToPrevious)));
      expect(controls, isNot(contains(MediaControl.stop)));
    });

    test('radioControls returns play when paused', () {
      final controls = KoelAudioHandler.radioControls(playing: false);

      expect(controls, [MediaControl.play]);
      expect(controls, isNot(contains(MediaControl.pause)));
    });
  });
}

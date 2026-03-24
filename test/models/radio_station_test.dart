import 'package:app/models/radio_station.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RadioStation.fromJson', () {
    test('parses all fields', () {
      final json = {
        'id': 'station-1',
        'name': 'Jazz FM',
        'url': 'https://stream.jazzfm.com/live',
        'logo': 'https://example.com/logo.png',
        'description': 'Smooth jazz all day',
        'is_public': true,
      };

      final station = RadioStation.fromJson(json);

      expect(station.id, 'station-1');
      expect(station.name, 'Jazz FM');
      expect(station.url, 'https://stream.jazzfm.com/live');
      expect(station.logo, 'https://example.com/logo.png');
      expect(station.description, 'Smooth jazz all day');
      expect(station.isPublic, isTrue);
    });

    test('handles null optional fields', () {
      final json = {
        'id': 'station-2',
        'name': 'Rock Radio',
        'url': 'https://stream.rock.com/live',
        'logo': null,
        'description': null,
        'is_public': false,
      };

      final station = RadioStation.fromJson(json);

      expect(station.logo, isNull);
      expect(station.description, isNull);
      expect(station.isPublic, isFalse);
    });
  });

  group('RadioStation.fake', () {
    test('generates a valid station', () {
      final station = RadioStation.fake();
      expect(station.id, isNotEmpty);
      expect(station.name, isNotEmpty);
      expect(station.url, isNotEmpty);
    });

    test('respects custom parameters', () {
      final station = RadioStation.fake(
        name: 'My Station',
        url: 'https://my.stream/live',
      );
      expect(station.name, 'My Station');
      expect(station.url, 'https://my.stream/live');
    });
  });
}

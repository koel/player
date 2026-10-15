import 'package:app/app_state.dart';
import 'package:app/utils/features.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:version/version.dart';

void main() {
  setUp(() => AppState.clear());

  group('Feature.radioStations', () {
    test('is supported when API version is 7.13.0', () {
      AppState.set(['app', 'apiVersion'], Version.parse('7.13.0'));
      expect(Feature.radioStations.isSupported(), isTrue);
    });

    test('is supported when API version is above 7.13.0', () {
      AppState.set(['app', 'apiVersion'], Version.parse('7.14.0'));
      expect(Feature.radioStations.isSupported(), isTrue);
    });

    test('is not supported when API version is below 7.13.0', () {
      AppState.set(['app', 'apiVersion'], Version.parse('7.12.0'));
      expect(Feature.radioStations.isSupported(), isFalse);
    });

    test('is not supported when API version is not set', () {
      expect(Feature.radioStations.isSupported(), isFalse);
    });
  });

  group('Feature.favoriteEntities', () {
    test('is supported when API version is 7.11.0', () {
      AppState.set(['app', 'apiVersion'], Version.parse('7.11.0'));
      expect(Feature.favoriteEntities.isSupported(), isTrue);
    });

    test('is supported when API version is above 7.11.0', () {
      AppState.set(['app', 'apiVersion'], Version.parse('7.13.0'));
      expect(Feature.favoriteEntities.isSupported(), isTrue);
    });

    test('is not supported when API version is below 7.11.0', () {
      AppState.set(['app', 'apiVersion'], Version.parse('7.10.0'));
      expect(Feature.favoriteEntities.isSupported(), isFalse);
    });

    test('is not supported when API version is not set', () {
      expect(Feature.favoriteEntities.isSupported(), isFalse);
    });
  });

  group('Feature.customPlaylistOrder', () {
    test('is supported at 7.0.2 and above', () {
      AppState.set(['app', 'apiVersion'], Version.parse('7.0.2'));
      expect(Feature.customPlaylistOrder.isSupported(), isTrue);
      AppState.set(['app', 'apiVersion'], Version.parse('9.0.0'));
      expect(Feature.customPlaylistOrder.isSupported(), isTrue);
    });

    test('is not supported below 7.0.2', () {
      AppState.set(['app', 'apiVersion'], Version.parse('7.0.1'));
      expect(Feature.customPlaylistOrder.isSupported(), isFalse);
    });
  });

  group('Feature.customFavoritesOrder', () {
    test('is supported at 9.0.0 and above', () {
      AppState.set(['app', 'apiVersion'], Version.parse('9.0.0'));
      expect(Feature.customFavoritesOrder.isSupported(), isTrue);
    });

    test('is not supported below 9.0.0', () {
      AppState.set(['app', 'apiVersion'], Version.parse('8.9.9'));
      expect(Feature.customFavoritesOrder.isSupported(), isFalse);
    });

    test('is not supported when API version is not set', () {
      expect(Feature.customFavoritesOrder.isSupported(), isFalse);
    });
  });

  group('Feature.podcasts', () {
    test('is supported when API version is 7.0.0 or above', () {
      AppState.set(['app', 'apiVersion'], Version.parse('7.0.0'));
      expect(Feature.podcasts.isSupported(), isTrue);
    });

    test('is not supported when API version is below 7.0.0', () {
      AppState.set(['app', 'apiVersion'], Version.parse('6.9.0'));
      expect(Feature.podcasts.isSupported(), isFalse);
    });
  });
}

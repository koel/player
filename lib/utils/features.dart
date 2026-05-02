import 'package:app/app_state.dart';
import 'package:version/version.dart';

enum Feature {
  podcasts,
  queueStateSync,
  radioStations,
  // Favorite/unfavorite for albums, artists, radio stations, and
  // podcasts (the song-level "like" predates this).
  favoriteEntities,
}

Map<Feature, String> supportedVersionMap = {
  Feature.podcasts: '7.0.0',
  Feature.queueStateSync: '6.11.6',
  Feature.radioStations: '7.13.0',
  Feature.favoriteEntities: '7.11.0',
};

extension FeatureExtension on Feature {
  bool isSupported() {
    try {
      return AppState.get<Version>(['app', 'apiVersion'])! >=
          Version.parse(supportedVersionMap[this]!);
    } catch (e) {
      return false;
    }
  }
}

import 'package:app/app_state.dart';
import 'package:version/version.dart';

enum Feature {
  podcasts,
  queueStateSync,
}

Map<Feature, String> supportedVersionMap = {
  Feature.podcasts: '7.0.0',
  Feature.queueStateSync: '6.11.6'
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

import 'package:app/app_state.dart';
import 'package:app/models/models.dart';
import 'package:app/utils/preferences.dart' as preferences;
import 'package:app/values/playable_sort_config.dart';
import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

abstract class Playable<T> {
  late String id;
  late num length;
  late String title;
  late DateTime createdAt;

  bool liked = false;
  int playCount = 0;

  bool playCountRegistered = false;

  Future<MediaItem> asMediaItem();

  T merge(T other);

  Comparable valueToCompare(PlayableSortConfig config);

  ImageProvider get image;

  String get sourceUrl;

  bool matchKeywords(String keywords);

  Map<String, dynamic> toJson();

  static Playable fromJson(Map<String, dynamic> json) {
    if (json['type'] == 'episodes') {
      return Episode.fromJson(json);
    }

    return Song.fromJson(json);
  }

  static Playable? tryFromJson(Map<String, dynamic> json) {
    try {
      return Playable.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  bool get hasCustomImage {
    return image is CachedNetworkImageProvider &&
        !(image as CachedNetworkImageProvider)
            .url
            .endsWith('/default-image.webp');
  }

  String get host {
    return AppState.get(['app', 'cdnUrl'], preferences.host)!
        .replaceAll(RegExp(r'/$'), '');
  }

  String get cacheKey => 'CACHE_$id';

  @override
  bool operator ==(Object other) => other is Playable && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

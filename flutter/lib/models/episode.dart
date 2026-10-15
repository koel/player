import 'package:app/models/models.dart';
import 'package:app/utils/preferences.dart' as preferences;
import 'package:app/values/playable_sort_config.dart';
import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

class Episode extends Playable<Episode> {
  String id;
  num length;
  String title;
  String podcastId;
  String podcastTitle;
  String podcastAuthor;
  String description;
  String imageUrl;
  String? link;
  DateTime createdAt;

  ImageProvider? _image;
  String? _cachedSourceUrl;

  Episode({
    required this.id,
    required this.length,
    required this.title,
    required this.podcastId,
    required this.podcastTitle,
    required this.podcastAuthor,
    required this.description,
    required this.imageUrl,
    required this.link,
    required this.createdAt,
  });

  @override
  Future<MediaItem> asMediaItem() async {
    return MediaItem(
      id: id,
      album: podcastTitle,
      title: title,
      artist: podcastAuthor,
      duration: Duration(seconds: length.toInt()),
      artUri: Uri.parse(imageUrl),
      genre: 'Podcast',
      extras: {
        'sourceUrl': sourceUrl,
        'type': 'episode',
      },
    );
  }

  @override
  ImageProvider get image {
    this._image ??= CachedNetworkImageProvider(this.imageUrl);
    return this._image!;
  }

  @override
  String get sourceUrl {
    this._cachedSourceUrl ??=
        Uri.encodeFull('$host/play/$id?t=${preferences.audioToken}');

    return this._cachedSourceUrl!;
  }

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'],
      length: json['length'],
      title: json['title'],
      podcastId: json['podcast_id'],
      podcastTitle: json['podcast_title'],
      podcastAuthor: json['podcast_author'],
      description: json['episode_description'],
      imageUrl: json['episode_image'],
      link: json['episode_link'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  @override
  Episode merge(Episode other) {
    this
      ..title = other.title
      ..length = other.length
      ..podcastId = other.podcastId
      ..podcastTitle = other.podcastTitle
      ..podcastAuthor = other.podcastAuthor
      ..description = other.description
      ..imageUrl = other.imageUrl
      ..link = other.link
      ..createdAt = other.createdAt;

    _image = null;

    return this;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'episodes',
      'id': id,
      'length': length,
      'title': title,
      'podcast_id': podcastId,
      'podcast_title': podcastTitle,
      'podcast_author': podcastAuthor,
      'episode_description': description,
      'episode_image': imageUrl,
      'episode_link': link,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool matchKeywords(String keywords) {
    return title.toLowerCase().contains(keywords) ||
        podcastTitle.toLowerCase().contains(keywords) ||
        podcastAuthor.toLowerCase().contains(keywords);
  }

  @override
  Comparable valueToCompare(PlayableSortConfig config) {
    switch (config.field) {
      case 'title':
        return title;
      case 'album_name':
        return podcastTitle;
      case 'artist_name':
        return podcastAuthor;
      case 'created_at':
        return createdAt;
      default:
        return '';
    }
  }
}

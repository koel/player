import 'package:app/enums.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

class Podcast {
  final String id;
  final String title;
  final String url;
  final String link;
  final String description;
  final String author;
  final String imageUrl;
  final String subscribedAt;
  final String lastPlayedAt;
  final PodcastState state;

  ImageProvider? _image;

  Podcast({
    required this.id,
    required this.title,
    required this.url,
    required this.link,
    required this.description,
    required this.author,
    required this.imageUrl,
    required this.subscribedAt,
    required this.lastPlayedAt,
    required this.state,
  });

  ImageProvider get image {
    this._image ??= CachedNetworkImageProvider(this.imageUrl);
    return this._image!;
  }

  factory Podcast.fromJson(Map<String, dynamic> json) {
    return Podcast(
      id: json['id'],
      title: json['title'],
      url: json['url'],
      link: json['link'],
      description: json['description'],
      author: json['author'],
      imageUrl: json['image'],
      subscribedAt: json['subscribed_at'],
      lastPlayedAt: json['last_played_at'],
      state: PodcastState.fromJson(json['state']),
    );
  }

  compare(Podcast other, PodcastSortField field) {
    switch (field) {
      case PodcastSortField.lastPlayedAt:
        return this.lastPlayedAt.compareTo(other.lastPlayedAt);
      case PodcastSortField.subscribedAt:
        return this.subscribedAt.compareTo(other.subscribedAt);
      case PodcastSortField.title:
        return this.title.compareTo(other.title);
      case PodcastSortField.author:
        return this.author.compareTo(other.author);
    }
  }
}

class PodcastState {
  final String? currentEpisodeId;
  final Map<String, dynamic> progresses;

  PodcastState({
    this.currentEpisodeId,
    required this.progresses,
  });

  factory PodcastState.fromJson(Map<String, dynamic> json) {
    return PodcastState(
        currentEpisodeId: json['current_episode'],
        progresses: parseProgressesFromJson(json['progresses']));
  }

  static Map<String, num> parseProgressesFromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return json.map((key, value) => MapEntry(key, value as num));
    } else {
      return {};
    }
  }
}

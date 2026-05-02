import 'package:app/enums.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:faker/faker.dart';
import 'package:flutter/widgets.dart';
import 'package:ulid/ulid.dart';

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

  /// Whether the current user has favorited this podcast. Mutable so
  /// the optimistic favorite toggle can flip it in place.
  bool favorite;

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
    this.favorite = false,
  });

  ImageProvider get image {
    this._image ??= CachedNetworkImageProvider(this.imageUrl);
    return this._image!;
  }

  factory Podcast.fake({
    String? id,
    String? title,
    String? author,
    bool favorite = false,
    PodcastState? state,
  }) {
    final faker = Faker();
    return Podcast(
      id: id ?? Ulid().toString(),
      title: title ?? faker.lorem.sentence(),
      url: 'https://example.com/feed.xml',
      link: 'https://example.com',
      description: faker.lorem.sentences(2).join(' '),
      author: author ?? faker.person.name(),
      imageUrl: faker.image.loremPicsum(width: 192, height: 192),
      subscribedAt: '2026-01-01T00:00:00Z',
      lastPlayedAt: '2026-01-01T00:00:00Z',
      state: state ?? PodcastState(progresses: {}),
      favorite: favorite,
    );
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
      favorite: json['favorite'] == true,
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

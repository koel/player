import 'package:app/models/podcast.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> baseJson() => {
        'id': 'p1',
        'title': 'A Podcast',
        'url': 'https://example.com/feed.xml',
        'link': 'https://example.com',
        'description': 'A description',
        'author': 'Author',
        'image': 'https://example.com/image.jpg',
        'subscribed_at': '2026-01-01T00:00:00Z',
        'last_played_at': '2026-01-02T00:00:00Z',
        'state': {'progresses': {}},
      };

  group('Podcast.fromJson', () {
    test('parses all fields', () {
      final podcast = Podcast.fromJson(baseJson());

      expect(podcast.id, 'p1');
      expect(podcast.title, 'A Podcast');
      expect(podcast.author, 'Author');
      expect(podcast.imageUrl, 'https://example.com/image.jpg');
      expect(podcast.subscribedAt, '2026-01-01T00:00:00Z');
      expect(podcast.lastPlayedAt, '2026-01-02T00:00:00Z');
    });

    test('parses favorite from JSON', () {
      final json = baseJson()..['favorite'] = true;
      expect(Podcast.fromJson(json).favorite, isTrue);
    });

    test('defaults favorite to false when missing or non-bool', () {
      expect(Podcast.fromJson(baseJson()).favorite, isFalse);
      for (final value in <Object?>[null, 0, 1, 'true', 'false']) {
        final json = baseJson()..['favorite'] = value;
        expect(
          Podcast.fromJson(json).favorite,
          isFalse,
          reason: 'favorite should be false for $value',
        );
      }
    });
  });

  group('Podcast.fake', () {
    test('generates a valid podcast', () {
      final podcast = Podcast.fake();
      expect(podcast.id, isNotEmpty);
      expect(podcast.title, isNotEmpty);
      expect(podcast.favorite, isFalse);
    });

    test('respects custom favorite flag', () {
      expect(Podcast.fake(favorite: true).favorite, isTrue);
    });
  });
}

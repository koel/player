import 'package:app/models/episode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exposes only its type in media item extras', () async {
    final episode = Episode(
      id: 'episode-1',
      length: 60,
      title: 'Test episode',
      podcastId: 'podcast-1',
      podcastTitle: 'Test podcast',
      podcastAuthor: 'Test author',
      description: 'Description',
      imageUrl: 'https://example.com/image.jpg',
      link: null,
      createdAt: DateTime(2024),
    );

    final mediaItem = await episode.asMediaItem();

    expect(mediaItem.extras, {'type': 'episode'});
  });
}

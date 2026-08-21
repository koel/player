import 'package:app/models/episode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('does not expose its authenticated source URL', () async {
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

    expect(mediaItem.extras?.containsKey('sourceUrl'), isFalse);
    expect(mediaItem.extras?['type'], 'episode');
  });
}
